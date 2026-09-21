package File::SOPS;
# ABSTRACT: Perl implementation of Mozilla SOPS encrypted file format

use Moo;
use Carp qw(carp croak);
use Cwd ();
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use File::Basename qw(basename);
use File::Spec;
use File::Temp ();
use Scalar::Util qw(blessed refaddr);
use Text::ParseWords qw(shellwords);
use Digest::SHA qw(sha512);
# Nothing below calls encode_json, decode_json or JSON(), and namespace::clean
# strips all three from this package.
#
# This line used to be load-bearing for the WIRE FORMAT: loading JSON::MaybeXS
# here, ahead of File::SOPS::Encrypted pulling in CryptX (which loads JSON.pm,
# and with it JSON::XS), was what decided the JSON backend for the process, and
# the backends do not emit or parse the same floats. It is not that any more --
# k56 / docs/adr/0005 -- because Format::JSON now names Cpanel::JSON::XS
# instead of inheriting whatever the calling program happened to bind. The
# ordering here no longer reaches a document.
#
# What is left is JSON::PP::Boolean for JSON->true/false, and that comes from
# File::SOPS::Encrypted's and File::SOPS::Metadata's own `use JSON::MaybeXS`,
# in the same files as the calls that need it (all three backends bless into
# JSON::PP::Boolean, so it is backend-independent). So this line is now a
# genuinely unused import -- which is what k49 first claimed and could not
# act on. Removing it is the API lane's call, not a wire question.
use JSON::MaybeXS;
# Used directly by _load_creation_rules to read a .sops.yaml, which is a config
# file rather than a SOPS document and so does not go through Format::YAML.
use YAML::XS ();
# No YAML::PP here any more. The order-preserving reparse the MAC needs is
# the format handler's, not this module's -- see _parse_in_document_order
# and docs/adr/0036.
use File::SOPS::Encrypted;
use File::SOPS::Metadata;
use File::SOPS::Backend::Age;
use File::SOPS::Format::YAML;
use File::SOPS::Format::JSON;
use File::SOPS::Format::ENV;
use File::SOPS::Format::INI;
use namespace::clean;

our $VERSION = '0.004';


my %FORMATS = (
    yaml   => 'File::SOPS::Format::YAML',
    yml    => 'File::SOPS::Format::YAML',
    json   => 'File::SOPS::Format::JSON',
    env    => 'File::SOPS::Format::ENV',
    # sops's own name for the format, accepted for the same reason `yml` is:
    # a caller who knows it from `--input-type dotenv` should not have to
    # translate. format_name stays 'env'.
    dotenv => 'File::SOPS::Format::ENV',
    ini    => 'File::SOPS::Format::INI',
);

# Whether a top-level `sops` entry in $data collides with the format's
# metadata namespace. YAML and JSON write their metadata section under that
# exact key, so a caller-supplied value would be overwritten -- the failure
# mode k18 describes. ENV and INI do not: ENV's metadata is in flat
# `sops_*` keys, INI's is in a `[sops]` section, so `data->{sops}` is a
# legitimate entry there (k157). Each handler's own serialize-time
# guard is the defensive double-check for direct callers of `serialize`;
# this hash is the source of truth for the format-blind guard in encrypt().
my %RESERVES_SOPS_KEY = (
    'File::SOPS::Format::YAML' => 1,
    'File::SOPS::Format::JSON' => 1,
    'File::SOPS::Format::ENV'  => 0,
    'File::SOPS::Format::INI'  => 0,
);

# Everything that describes HOW a document gets encrypted, as opposed to what
# gets encrypted or for whom. encrypt and encrypt_file must accept exactly the
# same set or the file API silently offers less than the string API does.
my @ENCRYPTION_OPTIONS = (
    @File::SOPS::Metadata::ENCRYPTION_RULES,
    'mac_only_encrypted',
    'metadata',
);

sub encrypt {
    my ($class, %args) = @_;
    my $data       = $args{data}       // croak "data required";
    my $recipients = $args{recipients} // croak "recipients required";
    my $format     = $args{format}     // 'yaml';

    # A single document is a HashRef; a multi-document YAML stream is an ArrayRef
    # of HashRefs, one per document (docs/adr/0033 Decision 1, k31). The
    # ArrayRef form is purely additive -- until 0.003 it raised "data must be a
    # hash ref" -- and what round-trips is the FILE: a one-element ArrayRef
    # writes a one-document file byte-identical to the same bare HashRef.
    croak "data must be a hash ref, or an array ref of hash refs for a "
        . "multi-document stream"
        unless ref($data) eq 'HASH' || ref($data) eq 'ARRAY';
    croak "recipients must be an array ref" unless ref($recipients) eq 'ARRAY';

    my @documents = ref $data eq 'ARRAY' ? @$data : ($data);
    croak "data must not be an empty array ref" unless @documents;

    # Resolved BEFORE the sops-key guard: the guard defers to the format handler
    # to decide whether a top-level `sops` entry collides with its metadata
    # namespace. YAML and JSON reserve that exact name; ENV and INI do not
    # (k157), so a bare `sops` data key is legitimate there.
    my $format_class = $FORMATS{$format} // croak "Unknown format: $format";

    # Per-document guards (docs/adr/0033 Decision 4). Each document is validated
    # and walked on its own: a tree that contains itself has no document to
    # write and would recurse until the process died, and the expansion guard
    # runs second and depends on it (its census memo fills on the way out, so a
    # cycle would hang it). ONE $active/$clean pair is shared across documents --
    # the ancestor set is unwound on the way out, so a HashRef a caller
    # legitimately shares between two documents is a DAG, not a cycle, and is not
    # refused; sharing $clean is a win. Depth and the alias budget stay
    # per-document because each document is entered by its own top-level call,
    # never the document list walked as a container. A single document is one
    # iteration, byte-identical to before.
    my ($active, $clean) = ({}, {});
    for my $doc (@documents) {
        croak "each document in data must be a hash ref" unless ref $doc eq 'HASH';
        croak _sops_key_reserved('data') if exists $doc->{sops}
            && $RESERVES_SOPS_KEY{$format_class};
        _assert_acyclic($doc, [], $active, $clean);
        _assert_expansion_bounded($doc);
    }

    # Generate random 256-bit data key. The one CSPRNG in this distribution
    # lives next to the per-value nonce that shares its failure mode; see the
    # comment on File::SOPS::Encrypted::_random_bytes for why a short return
    # has to be caught there and cannot be caught anywhere else.
    my $data_key = File::SOPS::Encrypted::_random_bytes(32);

    # Create metadata
    my $metadata = _metadata_for_encrypt(\%args);
    $metadata->update_lastmodified;

    # Encrypt data key for each recipient
    my $encrypted_keys = File::SOPS::Backend::Age->encrypt_data_key(
        data_key   => $data_key,
        recipients => $recipients,
    );
    $metadata->age($encrypted_keys);

    # Compute MAC over plaintext values BEFORE encryption (SOPS behavior).
    # _compute_mac spans every document in the list, in document order, each
    # contributing its own key order -- one digest over the whole stream
    # (docs/adr/0033 point 3). A single document is byte-identical.
    my $mac = _compute_mac($data, $data_key, $metadata);
    $metadata->mac($mac);

    # Only YAML has a document stream. Writing more than one document to a format
    # that has none would drop all but the first -- the k14 defect class,
    # which sops commits silently (docs/adr/0033 Decision 3, N1). Refuse instead,
    # naming the count and the target. A single document reaches every format.
    _assert_format_supports_stream($format_class, scalar @documents);

    # Encrypt every document's values under the one data key, then hand the list
    # to the emitter, which attaches the ONE metadata block to each document
    # byte-identically and joins them with `---` (docs/adr/0033 points 1, 5).
    # A single document passes a bare HashRef and is byte-identical to before --
    # serialize reduces a one-element list to the same single Dump either way,
    # and _encrypt_tree wants the document HashRef, never the ArrayRef wrapper
    # (docs/adr/0033 Decision 1, proven byte-identical).
    my @encrypted = map { _encrypt_tree($_, $data_key, $metadata, []) } @documents;

    return $format_class->serialize(
        data     => (@encrypted == 1 ? $encrypted[0] : \@encrypted),
        metadata => $metadata,
    );
}


sub decrypt {
    my ($class, %args) = @_;
    my $encrypted  = $args{encrypted}  // croak "encrypted required";
    my $identities = $args{identities} // croak "identities required";
    my $format     = $args{format};

    croak "identities must be an array ref" unless ref($identities) eq 'ARRAY';

    # Auto-detect format if not specified
    $format //= _detect_format($encrypted);

    my $format_class = $FORMATS{$format} // croak "Unknown format: $format";

    # Parse the encrypted content. The third value is the DOCUMENT LIST: one
    # element for a single document (byte-identical to before), N for a
    # multi-document YAML stream (docs/adr/0033, k31). $data is a synonym
    # for $documents->[0]. Only the YAML handler returns the list at all -- JSON,
    # ENV and INI have no document stream and return two values -- so a missing
    # third value is normalised to the single-document list every walk below
    # expects.
    my ($data, $metadata, $documents) = $format_class->parse($encrypted);
    $documents = [$data] unless ref $documents eq 'ARRAY';
    my $multi = @$documents > 1;

    # Asked here, ahead of both the metadata check and the data key, because
    # that is the order sops answers in: its unmarshalling error precedes
    # everything, and a cyclic document with no usable identity reports the
    # cycle rather than the missing key. Measured, the same holds for the
    # alias bomb: sops -d reports the aliasing, not the key. The order of the
    # two is load-bearing, see _expansion_census.
    #
    # One document per top-level call, never the document list as a container:
    # each document carries its own depth and alias budget (docs/adr/0033
    # Decision 4, N4). One $active/$clean pair is shared -- the ancestor set is
    # unwound on the way out, so it stays correct across documents, and sharing
    # $clean is a win. A single document is one iteration, identical to before.
    my ($active, $clean) = ({}, {});
    for my $doc (@$documents) {
        _assert_acyclic($doc, [], $active, $clean);
        _assert_expansion_bounded($doc);
    }

    # Metadata is taken from the FIRST document only (docs/adr/0033 point 2). A
    # stream carrying a sops section only in a later document therefore surfaces
    # no metadata and is refused right here, which is `sops metadata not found`
    # at sops -- rather than being read as though it had none at all.
    croak "No SOPS metadata found" unless $metadata;

    # Decrypt data key using age backend. max_stanzas is forwarded verbatim: when
    # the caller does not pass it, it arrives here as undef and the backend applies
    # its own default of 64 (CVE-2026-85783), so the absent-argument path stays
    # byte-identical. A caller with a legitimately large recipient list raises it.
    my $data_key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys    => $metadata->age,
        identities  => $identities,
        max_stanzas => $args{max_stanzas},
    );

    # Decrypt every document's values. One metadata block, one data key, applied
    # to each document -- the same tree walk per document.
    my @decrypted = map { _decrypt_tree($_, $data_key, $metadata, []) } @$documents;

    # One MAC over ALL documents in document order (docs/adr/0033 point 3). The
    # document list is passed as `data`; _verify_mac pairs each document's key
    # order (from the order-preserving reparse) with its own values by index. A
    # single-document list is byte-identical to passing the bare HashRef.
    _verify_mac(
        document     => $encrypted,
        data         => $documents,
        data_key     => $data_key,
        metadata     => $metadata,
        format_class => $format_class,
    ) unless $args{ignore_mac};

    # A stream really holding more than one document comes back as an ArrayRef
    # of HashRefs; one document stays a bare HashRef (docs/adr/0033 Decision 1).
    # What round-trips is the FILE, not the Perl container: encrypt given a
    # one-element ArrayRef writes a one-document file that reads back here as a
    # HashRef.
    return $multi ? \@decrypted : $decrypted[0];
}


sub encrypt_file {
    my ($class, %args) = @_;
    my $input      = $args{input}      // croak "input required";
    my $output     = $args{output}     // $args{input};
    my $recipients = $args{recipients} // croak "recipients required";
    my $format     = $args{format};

    # Auto-detect format from filename
    $format //= _detect_format_from_filename($input);

    my $content = _read_file($input, 'input file');

    # Parse to get data structure.
    #
    # parse() SPLITS OFF the sops section, so by the time $data reaches
    # encrypt() an already-encrypted input is indistinguishable from a plain
    # tree of ENC[...] strings -- which encrypt would happily wrap a second
    # time. $metadata being defined is exactly "the input had a top-level sops
    # entry", which is the condition sops itself refuses on.
    my ($data, $metadata, $documents) = _format_class($format)->parse($content);
    croak _sops_key_reserved("input file '$input'") if $metadata;

    # Forward the WHOLE document list, so a multi-document YAML input is
    # encrypted as the stream it is rather than as its first document alone
    # (docs/adr/0033, k31). Only YAML returns a list; JSON, ENV and INI
    # return no third value, so $data (the single document) is forwarded there.
    # A single-document YAML input forwards a one-element list, byte-identical.
    my $encrypted = $class->encrypt(
        data       => (ref $documents eq 'ARRAY' ? $documents : $data),
        recipients => $recipients,
        format     => $format,
        _encryption_options(\%args),
    );

    _replace_file($output, $encrypted);

    return 1;
}


sub encrypt_in_place {
    my ($class, %args) = @_;
    my $file       = $args{file}       // croak "file required";
    my $recipients = $args{recipients} // croak "recipients required";
    my $format     = $args{format} // _detect_format_from_filename($file);

    my $content = _read_file($file, 'file');

    # Same guard as encrypt_file, and it matters more here: there is no
    # separate output file to inspect afterwards, so an unnoticed double
    # encryption would have overwritten the only copy.
    my ($data, $metadata, $documents) = _format_class($format)->parse($content);
    croak _sops_key_reserved("file '$file'") if $metadata;

    # Forward the whole document list (see encrypt_file), so an in-place encrypt
    # of a multi-document YAML file rewrites every document rather than replacing
    # the file with its first one -- the k14 loss this ticket exists to fix.
    my $encrypted = $class->encrypt(
        data       => (ref $documents eq 'ARRAY' ? $documents : $data),
        recipients => $recipients,
        format     => $format,
        _encryption_options(\%args),
    );

    _replace_file($file, $encrypted);

    return 1;
}


sub decrypt_file {
    my ($class, %args) = @_;
    my $input      = $args{input}      // croak "input required";
    my $output     = $args{output}     // croak "output required";
    my $identities = $args{identities} // croak "identities required";
    my $format     = $args{format};

    $format //= _detect_format_from_filename($input);

    my $content = _read_file($input, 'input file');

    # Decrypt
    my $data = $class->decrypt(
        encrypted   => $content,
        identities  => $identities,
        format      => $format,
        ignore_mac  => $args{ignore_mac},
        max_stanzas => $args{max_stanzas},
    );

    my $decrypted = _serialize_plaintext($data, $format);

    _replace_file($output, $decrypted);

    return 1;
}


sub extract {
    my ($class, %args) = @_;
    my $file       = $args{file}       // croak "file required";
    my $path       = $args{path}       // croak "path required";
    my $identities = $args{identities} // croak "identities required";
    my $format     = $args{format};

    $format //= _detect_format_from_filename($file);

    my $content = _read_file($file, 'file');

    my $document = $args{document} // 0;
    croak "document must be a non-negative integer, not '$document'"
        unless $document =~ /\A\d+\z/;

    my $data = $class->decrypt(
        encrypted   => $content,
        identities  => $identities,
        format      => $format,
        ignore_mac  => $args{ignore_mac},
        max_stanzas => $args{max_stanzas},
    );

    # A single-document file decrypts to a HashRef, a multi-document stream to an
    # ArrayRef of them (docs/adr/0033, k31). The path language stays sops's
    # -- applied to the ONE document `document` names -- because sops has no
    # document axis and cannot grow one: a leading integer already means "the Nth
    # key of document 0" there (docs/adr/0033 N2). So `document` is a separate
    # argument, defaulting to 0, and it addresses the stream by index.
    my @docs = ref $data eq 'ARRAY' ? @$data : ($data);
    croak sprintf(
        "document => %d is beyond the last document of '%s': the file has %d "
        . "document%s (indices 0..%d)",
        $document, $file, scalar @docs,
        (@docs == 1 ? '' : 's'), $#docs)
        if $document > $#docs;

    # Navigate WITHIN the named document; never fall through to a later one
    # looking for a key, which would turn a caller's typo into a plausible answer
    # from the wrong document. The path-not-found error names which document was
    # searched, so a mistake in `document` does not read as a mistake in `path`.
    my $where_doc = @docs > 1 ? "document $document" : undef;

    # A float leaf goes out carrying its canonical decimal as its string form: a
    # decrypted float is a bare NV, so printing it went through Perl's 15
    # significant digits and lost the digits the document actually holds (karr
    # k61, ADR 0010). Only this leaf -- a dualvar inside a tree changes what the
    # emitters write, so nothing that returns a tree does this, and a branch
    # extract returns comes back untouched.
    return File::SOPS::Encrypted->canonical_float_dualvar(
        _extract_path($docs[$document], $path, $where_doc));
}


sub rotate {
    my ($class, %args) = @_;
    my $file       = $args{file}       // croak "file required";
    my $identities = $args{identities} // croak "identities required";
    my $recipients = $args{recipients};
    my $format     = $args{format};

    $format //= _detect_format_from_filename($file);

    my $content = _read_file($file, 'file');

    my (undef, $metadata) = _format_class($format)->parse($content);
    croak "No SOPS metadata found in '$file'" unless $metadata;

    _assert_rekeyable($metadata, $file, verb => 'rotate', noun => 'Rotation');

    # Same question as edit's, and asked in the same place: the read below no
    # longer refuses a rule RE2 cannot compile, so the refusal for writing
    # under one belongs ahead of it rather than after the whole document has
    # been decrypted. docs/adr/0051.
    $metadata->assert_rule_regexes_agree;

    # Get current recipients if not specified
    unless ($recipients) {
        $recipients = [ map { $_->{recipient} } @{$metadata->age} ];
    }

    # Decrypt
    my $data = $class->decrypt(
        encrypted   => $content,
        identities  => $identities,
        format      => $format,
        ignore_mac  => $args{ignore_mac},
        max_stanzas => $args{max_stanzas},
    );

    # docs/adr/0046's guard stood here and is gone: the decryption above is
    # rule-driven now (docs/adr/0049), so a leaf the rule excludes comes back
    # as its own ENC[...] text and the re-encryption writes that text -- there
    # is no plaintext left for this method to leak. A document whose rule and
    # whose stored values disagree fails on the MAC, inside decrypt, which is
    # where sops fails it.

    # Re-encrypt with new data key, under the rules this document already had
    my $encrypted = $class->encrypt(
        data       => $data,
        recipients => $recipients,
        format     => $format,
        metadata   => $metadata,
    );

    _replace_file($file, $encrypted);

    return 1;
}


sub edit {
    my ($class, %args) = @_;
    my $file       = $args{file}       // croak "file required";
    my $identities = $args{identities} // croak "identities required";
    my $format     = $args{format} // _detect_format_from_filename($file);

    # Resolved BEFORE anything is decrypted: an unusable editor must not be
    # discovered with a plaintext copy of the document already on disk.
    my @editor = _editor_command($args{editor});

    my $content = _read_file($file, 'file');

    my (undef, $metadata, $documents) = _format_class($format)->parse($content);
    croak "No SOPS metadata found in '$file'" unless $metadata;

    # edit on a multi-document stream is deliberately NOT enabled. Reading and
    # writing streams both work now, so the mechanics would fall out -- but edit
    # re-encrypts under a NEW data key (unlike sops edit, k41), and
    # docs/adr/0033 explicitly leaves edit-on-a-stream semantics open ("What this
    # does not decide"). Shipping a working edit here would settle k41 by
    # accident, so it is refused instead, before the whole file is decrypted and
    # its plaintext written to a temp file for the editor. See _refuse_edit_multidoc.
    _refuse_edit_multidoc($documents);

    # Re-encryption here generates a NEW data key, exactly as rotate does, so
    # it inherits rotate's refusal: a document also wrapped for pgp or a KMS
    # would come back out with those recipients silently dropped.
    _assert_rekeyable($metadata, $file, verb => 'edit', noun => 'Editing');

    # And the document's own rule has to be one we can write under, asked HERE
    # rather than left to the re-encryption at the bottom. The read below now
    # goes through for a rule RE2 cannot compile (docs/adr/0051), so without
    # this the editor would open, the user would type, and the refusal would
    # arrive afterwards -- with their edit in a temp file and nowhere else.
    $metadata->assert_rule_regexes_agree;

    my $data = $class->decrypt(
        encrypted   => $content,
        identities  => $identities,
        format      => $format,
        ignore_mac  => $args{ignore_mac},
        max_stanzas => $args{max_stanzas},
    );

    # docs/adr/0046's guard stood here too and is gone for rotate's reason
    # (docs/adr/0049). What replaces it is still ahead of the editor: the
    # decryption above is where such a document now stops, on its MAC.

    my $before = _serialize_plaintext($data, $format);
    my $after  = _edit_text($before, $file, \@editor);

    # Nothing was changed: leave the file alone entirely rather than rewriting
    # an identical document under a new data key, MAC and lastmodified. sops
    # stops here too ("File has not changed, exiting.", exit code 200).
    return 0 unless defined $after;

    my ($edited, $edited_metadata) = do {
        my @parsed = eval { _format_class($format)->parse($after) };
        my $err    = $@;

        # A top-level `sops` entry of the user's own is NOT a parse failure and
        # must not be reported as one -- `sops: mine` parses perfectly, it just
        # cannot be encrypted over a metadata section that goes in the same
        # place, and the remedy is to rename one key rather than to hunt for a
        # syntax error that is not there.
        #
        # parse() reports the two shapes of that entry differently: a mapping
        # comes back as metadata, and every other shape (a scalar, a list, an
        # explicit null) is refused inside parse() by
        # File::SOPS::Metadata::from_hash, so it arrives here as an exception
        # and has to be sorted back out of the parse branch. Both shapes end at
        # the same croak.
        #
        # sops draws the line in exactly this place, with two distinct messages
        # (measured on 3.13.3 in editor mode): "Could not load tree, probably
        # due to invalid syntax" for text that does not parse, and "Tree not
        # valid for encryption" plus the reserved-key text for a top-level
        # `sops` entry -- for a scalar, a list, a null and a mapping alike.
        croak _edited_sops_key_reserved($file) if _is_sops_not_a_mapping($err);

        croak "The edited document does not parse (" . _reason($err) . "). "
            . "'$file' is unchanged, and the edited text has been discarded "
            . "together with the temporary file it was in -- there is no copy "
            . "of it left. sops keeps the editor open until the document "
            . "parses; this method cannot, because it may have no terminal to "
            . "return to."
            if $err;

        # If the editor turned the document into a multi-document stream, refuse
        # it for the same reason a multi-document original is refused above:
        # edit-on-a-stream semantics are undecided (k41, docs/adr/0033), not
        # that the write cannot be done. $parsed[2] is the document list parse()
        # returns as its third value.
        _refuse_edit_multidoc($parsed[2]);

        @parsed;
    };

    croak _edited_sops_key_reserved($file) if $edited_metadata;

    my $encrypted = $class->encrypt(
        data       => $edited,
        recipients => [ map { $_->{recipient} } @{ $metadata->age } ],
        format     => $format,
        metadata   => $metadata,
    );

    _replace_file($file, $encrypted);

    return 1;
}


# The config file, spelled exactly. Measured against sops 3.13.3: a .sops.yml
# is NOT read, and is warned about -- `ignoring "../.sops.yml" when searching
# for config file; the config file must be called ".sops.yaml"`.
our $CONFIG_FILE_NAME = '.sops.yaml';

# Creation-rule fields that name key material this distribution cannot produce.
#
# These are the CONFIG file's names, which are NOT the sops section's names:
# `azure_keyvault` and `hc_vault_transit_uri` here against `azure_kv` and
# `hc_vault` there. Measured against sops 3.13.3 by putting an unusable key in
# each field of a matching rule -- these five make it try to wrap the data key
# and fail on the key, while `aws_kms`, `azure_kv` and `hc_vault` in a creation
# rule are ignored entirely. Taking the list from
# @File::SOPS::Metadata::KEY_MATERIAL_FIELDS instead would therefore have let
# azure_keyvault and hc_vault_transit_uri walk straight through the guard.
#
# key_groups and shamir_threshold are here for the same reason one step on:
# both change how the data key is split and wrapped, sops writes
# shamir_threshold into the document it produces (measured), and a document
# this encrypted while ignoring them would be wrapped for age alone.
my @UNIMPLEMENTED_RULE_FIELDS = qw(
    pgp kms gcp_kms azure_keyvault hc_vault_transit_uri
    key_groups shamir_threshold
);

sub creation_rules_for {
    my ($class, %args) = @_;
    my $file = $args{file} // croak "file required";

    my $target = _clean_abs_path($file);

    my $config = $args{config};
    unless (defined $config) {
        $config = _find_config_file($target);
        croak "No $CONFIG_FILE_NAME found for '$file': looked in '"
            . _dir_of($target) . "' and in every directory above it, up to the "
            . "filesystem root. Pass recipients to encrypt yourself, or "
            . "config => '/path/to/$CONFIG_FILE_NAME' to name one. (sops stops "
            . "here too: \"config file not found, or has no creation rules, and "
            . "no keys provided through command line options\".)"
            unless defined $config;
    }

    my $rules   = _load_creation_rules($config);
    my $subject = _rule_subject_path($target, $config);

    my ($rule, $index) = _first_matching_rule($rules, $subject, $config);
    croak "No creation rule in '$config' matches '$subject'. A rule matches "
        . "when its path_regex matches that path -- which is '$file' resolved "
        . "and taken relative to the directory holding the config file -- or "
        . "when it has no path_regex at all, which is how a catch-all rule is "
        . "written. (sops stops here too: \"error loading config: no matching "
        . "creation rules found\".)"
        unless $rule;

    return _creation_rule_args($rule, $config, $index);
}


# Internal helpers

sub _format_class {
    my ($format) = @_;
    return $FORMATS{$format} // croak "Unknown format: $format";
}

# --- .sops.yaml creation rules -------------------------------------------
#
# Everything below is path arithmetic and a regex match. No wire bytes, no MAC,
# no crypto: this decides which recipients and which encryption rule a file is
# encrypted under, and then the ordinary encrypt path does the work.

# An absolute path the way Go's filepath.Abs + Clean makes one: relative to the
# current directory, with '.' and '..' resolved TEXTUALLY, and without touching
# the filesystem. Cwd::abs_path is deliberately not used -- it resolves
# symlinks, and sops does not: measured on 3.13.3, encrypting a symlink matches
# a path_regex against the LINK's path, not the target's. It also requires the
# file to exist, and a file about to be created still needs its rules.
sub _clean_abs_path {
    my ($path) = @_;

    my ($vol, $dirs, $file) = File::Spec->splitpath(File::Spec->rel2abs($path));

    my @parts;
    for my $part (File::Spec->splitdir($dirs), $file) {
        next if !length $part || $part eq File::Spec->curdir;
        if ($part eq File::Spec->updir) { pop @parts; next }
        push @parts, $part;
    }

    return File::Spec->catpath($vol,
        File::Spec->catdir(File::Spec->rootdir, @parts), '');
}

sub _dir_of {
    my ($abs) = @_;
    my ($vol, $dirs) = File::Spec->splitpath($abs);
    return File::Spec->canonpath(File::Spec->catpath($vol, $dirs, ''));
}

# The nearest .sops.yaml at or above the file's own directory, or undef.
#
# The search starts at the FILE, where sops starts it at the current working
# directory (measured on 3.13.3; see creation_rules_for for why this deviates).
# Nothing stops the walk short of the root -- not .git, not $HOME -- which is
# what sops does.
sub _find_config_file {
    my ($target) = @_;

    my ($vol, $dirs) = File::Spec->splitpath($target);
    my @parts = grep { length } File::Spec->splitdir($dirs);

    while (1) {
        my $dir = File::Spec->catpath($vol,
            File::Spec->catdir(File::Spec->rootdir, @parts), '');
        my $candidate = File::Spec->catfile($dir, $CONFIG_FILE_NAME);
        return $candidate if -f $candidate;
        last unless @parts;
        pop @parts;
    }

    return undef;
}

# The string path_regex is matched against: the file relative to the directory
# holding the config file, or -- when it is not under that directory at all --
# the absolute path. Measured on sops 3.13.3, both halves of it: a config at
# the top of a tree matches `a/b/c/secrets.yaml` however the file was named and
# from wherever sops was run, and a file outside the config's directory matches
# `^/` rather than `^\.\./`.
#
# With the config found by walking up from the file, the second case cannot
# arise -- the file is under the config's directory by construction. It is
# reachable only through an explicit `config`.
sub _rule_subject_path {
    my ($target, $config) = @_;

    my $rel = File::Spec->abs2rel($target, _dir_of(_clean_abs_path($config)));
    my ($first) = File::Spec->splitdir($rel);

    return $target if !length $rel || $first eq File::Spec->updir;
    return $rel;
}

sub _load_creation_rules {
    my ($config) = @_;

    my $content = _read_file($config, 'config file');

    # LIST context, as the format handlers use it: YAML::XS::Load in scalar
    # context returns the LAST document of a multi-document stream, which for a
    # config file would silently honour one half of it.
    my @docs = eval { YAML::XS::Load($content) };
    croak "Cannot parse config file '$config' (" . _reason($@) . "). sops "
        . "stops on the same file with \"error loading config: Could not "
        . "unmarshal config file\"."
        if $@;

    croak "Config file '$config' holds " . scalar(@docs) . " YAML documents; a "
        . "$CONFIG_FILE_NAME is a single mapping"
        if @docs > 1;

    my $conf = @docs ? $docs[0] : undef;

    croak "Config file '$config' has no creation_rules, so there is nothing "
        . "in it that says who a file should be encrypted for. (sops reports "
        . "\"config file not found, or has no creation rules, and no keys "
        . "provided through command line options\".)"
        if !defined $conf || (ref $conf eq 'HASH' && !defined $conf->{creation_rules});

    croak "Config file '$config' is not a mapping" unless ref $conf eq 'HASH';

    my $rules = $conf->{creation_rules};
    croak "creation_rules in '$config' is not a list"
        unless ref $rules eq 'ARRAY';

    return $rules;
}

sub _first_matching_rule {
    my ($rules, $subject, $config) = @_;

    my $index = 0;
    for my $rule (@$rules) {
        $index++;

        croak "Creation rule $index in '$config' is not a mapping"
            unless ref $rule eq 'HASH';

        my $regex = $rule->{path_regex};

        # No path_regex is a catch-all, which is how the last rule in a
        # .sops.yaml is usually written. Same in sops.
        return ($rule, $index) unless defined $regex && length $regex;

        # sops compiles the same string with Go RE2, which is not the same
        # dialect. A pattern the two dialects do not agree on -- one RE2
        # rejects, or one both take and read differently -- silently selects
        # a different rule in sops (or none), so the two tools disagree
        # without either one saying so. The scan is the one in Metadata
        # (k164): it is escape-aware, character-class aware, and reads
        # every construct's RE2 verdict off the .sops.yaml oracle rather than
        # guessing. We translate the kind into a path_regex-specific message
        # because sops's behaviour here is different -- it REPORTS the
        # unsupported case as "error parsing regexp" rather than discarding
        # the compile error -- and the two croaks describe different things.
        # This runs BEFORE the real Perl match attempt below (mirroring
        # Metadata::_rule_verdict's order, k197), so a divergent construct
        # such as \Q/\E never reaches a live regex compile/match here -- that
        # would otherwise warn ("Unrecognized escape \Q passed through...")
        # on STDERR for a pattern Perl merely tolerates rather than reads the
        # way RE2 does.
        my ($construct, $kind) = _re2_path_regex_diagnosis($regex);
        if ($construct) {
            my $shown = length($regex) > 60
                ? substr($regex, 0, 57) . '...'
                : $regex;
            croak "Creation rule $index in '$config' has a path_regex "
                . "('$shown') that uses $construct, "
                . ($kind eq 'different'
                    ? "which Go RE2 and Perl both accept but read "
                    . "DIFFERENTLY, so this side would select a different "
                    . "rule than sops. "
                    : "which Go RE2 does not support and sops will refuse "
                    . "to compile. ")
                . "Either rewrite the pattern in constructs both dialects "
                . "agree on, or drop the rule. See the POD on "
                . "creation_rules_for.";
        }

        my $matched = eval { $subject =~ /$regex/ ? 1 : 0 };
        croak "Cannot use the path_regex of creation rule $index in '$config' "
            . "as a regular expression (" . _reason($@) . "). It is compiled as "
            . "a Perl regex here and with Go's RE2 by sops, which accept "
            . "different things -- sops reports this one too, as \"error "
            . "parsing regexp\"."
            if $@;

        return ($rule, $index) if $matched;
    }

    return;
}

# What in this path_regex, if any, the two regex dialects do not agree on.
# Returns the construct name and the kind of disagreement (the same two
# Metadata::_re2_divergent_construct returns: 'unsupported' for a construct
# RE2 cannot compile, 'different' for one both take and read apart), or
# the empty list when the pattern is in both dialects.
#
# The scan is the one in Metadata.pm (k161 / docs/adr/0048, broadened
# by k164 to also cover the path_regex case). The narrow check this
# replaces (k53) named lookarounds and backreferences only; atomic
# groups, possessive quantifiers, \Z, \K, the (?x) family and the rest of
# the RE2-rejected set were still being taken here and silently picking a
# different rule at sops -- measured on sops 3.13.3 against a .sops.yaml
# path_regex: each one of those triggers "error parsing regexp" at exit 1
# there.
sub _re2_path_regex_diagnosis {
    my ($regex) = @_;

    my @divergent = File::SOPS::Metadata::_re2_divergent_construct($regex);
    return @divergent;
}

# Is a creation rule's field set, in the sense Go's zero value gives it? An
# empty string, an empty list and an absent key are all "not set".
sub _rule_field_set {
    my ($rule, $name) = @_;

    my $value = $rule->{$name};
    return 0 unless defined $value;
    return scalar @$value       if ref $value eq 'ARRAY';
    return scalar keys %$value  if ref $value eq 'HASH';
    return length $value;
}

# A creation rule's `age`, as a list of recipients. Comma-separated, or a YAML
# list, or a list of comma-separated strings; whitespace around each recipient
# is dropped, which is what makes the folded `age: >-` form work. A NEWLINE is
# not a separator: measured on sops 3.13.3, a literal block of recipients with
# no commas reaches age as one string and fails to parse.
sub _age_recipients {
    my ($value, $config, $index) = @_;

    return () unless defined $value;

    my @out;
    for my $entry (ref $value eq 'ARRAY' ? @$value : $value) {
        croak "The age entry of creation rule $index in '$config' holds a "
            . lc(ref $entry) . " reference; it takes a recipient, a "
            . "comma-separated list of them, or a YAML list"
            if ref $entry;
        next unless defined $entry;

        for my $recipient (split /,/, $entry) {
            $recipient =~ s/\A\s+//;
            $recipient =~ s/\s+\z//;
            push @out, $recipient if length $recipient;
        }
    }

    return @out;
}

sub _creation_rule_args {
    my ($rule, $config, $index) = @_;

    my @unimplemented = grep { _rule_field_set($rule, $_) }
        @UNIMPLEMENTED_RULE_FIELDS;

    croak "Refusing to encrypt under creation rule $index in '$config': it "
        . "names key material this distribution cannot produce ("
        . join(', ', @unimplemented) . ") -- age is the only backend "
        . "implemented here. sops "
        . "wraps the data key for every backend a rule names, so encrypting "
        . "under this rule while ignoring those fields would write a document "
        . "the config says several parties can read and only the age "
        . "recipients actually can, and report success. Encrypt such a file "
        . "with the sops CLI, or pass recipients to encrypt yourself."
        if @unimplemented;

    my @recipients = _age_recipients($rule->{age}, $config, $index);
    croak "Creation rule $index in '$config' matches, but names no age "
        . "recipient, so there is nobody to encrypt for. (sops stops on the "
        . "same rule with \"Could not generate data key: [empty key group "
        . "provided]\".)"
        unless @recipients;

    my %args = (recipients => \@recipients);

    # The same mutual exclusion File::SOPS::Metadata enforces on a document,
    # asked here so the message can name the config file rather than the
    # document that could not be built out of it. sops refuses such a rule at
    # config-load time too, listing the same six names.
    my @rules = grep { _rule_field_set($rule, $_) }
        @File::SOPS::Metadata::ENCRYPTION_RULES,
        @File::SOPS::Metadata::UNSUPPORTED_ENCRYPTION_RULES;

    croak "Creation rule $index in '$config' uses more than one of "
        . join(', ', @File::SOPS::Metadata::ENCRYPTION_RULES,
                     @File::SOPS::Metadata::UNSUPPORTED_ENCRYPTION_RULES)
        . " (got " . join(' and ', @rules) . "); they select which values get "
        . "encrypted and at most one may be given. sops refuses the same rule."
        if @rules > 1;

    if (my ($name) = @rules) {
        croak "Refusing to encrypt under creation rule $index in '$config': "
            . "'$name' selects values by their comment, and neither of this "
            . "distribution's parsers keeps comments, so every value would be "
            . "classified wrongly. Use the sops CLI for files that config "
            . "covers."
            if grep { $_ eq $name }
                @File::SOPS::Metadata::UNSUPPORTED_ENCRYPTION_RULES;

        $args{$name} = $rule->{$name};
    }

    $args{mac_only_encrypted} = $rule->{mac_only_encrypted} ? 1 : 0
        if exists $rule->{mac_only_encrypted};

    return %args;
}

sub _read_file {
    my ($path, $what) = @_;

    open my $fh, '<:raw', $path
        or croak "Cannot open $what '$path': $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    return $content;
}

# The plaintext form of a decrypted tree: what decrypt_file writes out and what
# edit hands to the editor. Both have to agree, because edit compares the text
# it wrote with the text it gets back to decide whether anything changed.
#
# It is the format handler's own emitter, with no metadata section -- the same
# sub the handler's serialize() dumps through. Until k35 this WAS a second
# emitter, because the handlers only offered "serialize a document WITH its sops
# section", and it kept its options in sync with theirs by hand: a copy of
# JSON::MaybeXS->new(utf8/pretty/canonical) for JSON, and for YAML a boolean
# mode that at first was not set here at all and worked only because loading
# File::SOPS::Format::YAML assigned $YAML::XS::Boolean process-wide. Those
# options decide sorted key order, which the MAC's encrypt side depends on, so
# the twin was one edit away from a document that fails its own digest.
sub _serialize_plaintext {
    my ($data, $format) = @_;

    # _format_class croaks on an unknown format, before anything is written.
    my $format_class = _format_class($format);

    # A decrypted multi-document stream (docs/adr/0033, k31) is an ArrayRef
    # of documents. This is the one boundary where a decrypted stream meets a
    # plaintext output format, so Decision 3 -- the refusal to convert a stream
    # to a format that has no document stream (JSON, ENV, INI) rather than drop
    # all but its first document as sops does silently -- lives here as well as
    # on the encrypt path. A YAML target emits the stream through emit().
    my @docs = ref $data eq 'ARRAY' ? @$data : ($data);
    _assert_format_supports_stream($format_class, scalar @docs);

    return $format_class->emit($data);
}

# Decision 3 (docs/adr/0033, k14): a multi-document stream can only be
# written as YAML. Every other format has no document stream, so writing one to
# it would drop all but the first document -- which sops does silently, exit 0
# (N1). We refuse instead, naming the count and the target. Shared by the
# encrypt (serialize) path and the decrypt_file (emit) path so the two agree. A
# single document (or none) reaches every format and passes straight through.
sub _assert_format_supports_stream {
    my ($format_class, $count) = @_;

    return if $count <= 1;

    my $name = $format_class->can('format_name')
        ? $format_class->format_name : "$format_class";
    return if $name eq 'yaml';

    croak sprintf(
        "cannot write a multi-document stream (%d documents) as %s: that format "
        . "has no document stream, so all but the first document would be lost. "
        . "sops drops them silently here; this library refuses instead "
        . "(docs/adr/0033 Decision 3, k14). Use YAML, or write one document "
        . "at a time.",
        $count, $name);
}

# Write $content to $path, atomically: the content goes to a temporary file in
# the SAME directory (so the rename cannot cross a filesystem) and that file is
# renamed over the target. Nothing observes a partial write, and a failure
# anywhere before the rename leaves whatever was there untouched.
#
# EVERY method here that writes a file goes through this, whether the target
# exists or not. Until 0.003 only encrypt_in_place and edit did: encrypt_file,
# decrypt_file and rotate opened the target with '>', which truncates it before
# the first byte is written, and then checked neither the print nor the close --
# so a write that ran out of disk left an empty file and returned success.
# encrypt_file defaults output to input and rotate always writes back over the
# file it read, so what that destroyed was the only copy.
#
# This is where this distribution differs from sops, which truncates the file
# and rewrites it. Truncate-and-rewrite keeps the inode -- hard links and the
# open handle someone else holds see the new content -- at the price of
# destroying the file if the write stops half way. On a file whose only copy is
# about to be replaced by a re-encryption of itself, that trade goes the other
# way round.
#
# A symlink is resolved first, so the target is replaced rather than the link;
# measured against sops 3.13.3, `sops -e -i` on a symlink leaves the link alone
# and rewrites the target too. Hard links to the target are NOT preserved; they
# keep the old content, and that is documented on the methods that call this.
sub _replace_file {
    my ($path, $content) = @_;

    my $target = -l $path ? (Cwd::abs_path($path) // $path) : $path;

    # k46: sops -e -i refuses a read-only file with EACCES; the atomic
    # write was happy because rename() checks the directory, not the file.
    # This is a behaviour change introduced by the atomic write itself, where
    # the old open '>' would have failed on the chmod for free. Match sops
    # and refuse here, before any work -- a different inode is no
    # consolation when the file was deliberately read-only.
    croak "Could not open in-place file for writing: $target: permission denied"
        if -e $target && !-w $target;

    return _write_through($target, $content) if -e $target && !-f $target;

    # The mode to end up with: the one the file already has, or -- when there
    # is no file yet -- the one open '>' would have given it. File::Temp
    # creates 0600, so without this, preserving a deliberately group-readable
    # file would quietly tighten it and routing a write path through here would
    # be a permissions change as well as an atomicity one. sops's --output
    # creates at 0666 against the umask as well (measured: 0644 under umask
    # 022), and leaves an existing file's mode alone.
    my $existing = (stat $target)[2];
    my $mode = defined $existing ? $existing & 07777 : 0666 & ~umask;

    my ($vol, $dir, $base) = File::Spec->splitpath($target);
    $dir = File::Spec->curdir unless length $dir;

    # tempfile() croaks with its own wording when the directory is missing or
    # unwritable. That used to be "Cannot open output file '...': $!" and has
    # to stay something that names the file the caller asked for.
    my ($fh, $tmp) = eval {
        File::Temp::tempfile(
            ".$base.sops-XXXXXXXX",
            DIR    => File::Spec->catpath($vol, $dir, ''),
            UNLINK => 0,
        );
    };
    croak "Cannot create a temporary file next to '$target' to write it "
        . "atomically (" . _reason($@) . ")"
        unless defined $fh;

    my $ok = eval {
        binmode $fh, ':raw';
        print {$fh} $content
            or croak "Cannot write to temporary file '$tmp': $!";
        close $fh
            or croak "Cannot write to temporary file '$tmp': $!";

        chmod $mode, $tmp
            or croak "Cannot set permissions on '$tmp': $!";

        rename $tmp, $target
            or croak "Cannot replace '$target' with '$tmp': $!";
        1;
    };

    unless ($ok) {
        my $err = $@;
        close $fh;
        unlink $tmp;
        croak $err;
    }

    return 1;
}

# The one target temp-file-and-rename cannot serve: something that exists and
# is not a regular file -- /dev/stdout, /dev/null, a fifo. There is no previous
# content to protect there, and renaming over it would replace the device or
# the fifo itself with an ordinary file. `sops --output /dev/stdout` works, so
# this has to keep working.
#
# Every step is checked, unlike the open/print/close this replaced elsewhere:
# an unreported short write was half of what made that path dangerous.
sub _write_through {
    my ($path, $content) = @_;

    open my $fh, '>:raw', $path
        or croak "Cannot open output file '$path': $!";
    print {$fh} $content
        or do { my $err = $!; close $fh; croak "Cannot write to '$path': $err" };
    close $fh
        or croak "Cannot write to '$path': $!";

    return 1;
}

# The editor to run, as a list, without a shell in between. A string is split
# the way a shell would split it -- `EDITOR="code --wait"` is a command with an
# argument, not a program with a space in its name -- which is what sops does
# with $EDITOR as well.
sub _editor_command {
    my ($editor) = @_;

    $editor //= $ENV{EDITOR};

    croak "No editor to run: pass editor => 'vim' to edit, or set the EDITOR "
        . "environment variable. (sops falls back to vim, nano or vi when "
        . "EDITOR is unset; this does not, because a library that opens an "
        . "interactive editor nobody asked for hangs an unattended script "
        . "instead of failing it.)"
        unless defined $editor && length $editor;

    my @command = ref $editor eq 'ARRAY' ? @$editor : shellwords($editor);
    croak "The editor command '" . (ref $editor eq 'ARRAY' ? join(' ', @$editor) : $editor)
        . "' is empty once split into words"
        unless @command;

    return @command;
}

# Put $text in front of the editor and return what came back, or undef if it
# was left byte for byte identical.
#
# The plaintext lives in a directory of its own for as long as this call, and
# no longer. File::Temp's object removes the tree when $tmpdir goes out of
# scope, which covers returning and dying alike; the handlers below cover being
# signalled, where the default disposition would terminate the process without
# running a destructor.
#
# SIGINT is deliberately in that list even though Ctrl-C during the editor does
# not arrive here: perl's system() ignores SIGINT for the duration of the child
# (perlfunc), so the interrupt reaches the EDITOR and comes back as a non-zero
# wait status, which the croak below turns into ordinary unwinding. The handler
# is for a SIGINT arriving in the rest of this call.
sub _edit_text {
    my ($text, $file, $editor) = @_;

    my $tmpdir = File::Temp->newdir(TEMPLATE => 'file-sops-edit-XXXXXXXX',
                                    TMPDIR   => 1);

    my $on_signal = sub {
        my ($signal) = @_;
        undef $tmpdir;              # removes the plaintext, now
        $SIG{$signal} = 'DEFAULT';  # and then die of the signal we were sent
        kill $signal, $$;
    };
    local $SIG{INT}  = $on_signal;
    local $SIG{TERM} = $on_signal;
    local $SIG{HUP}  = $on_signal;

    # Same basename as the original, so the editor's filetype detection sees
    # the extension it expects. sops does this too.
    my $path = File::Spec->catfile("$tmpdir", basename($file));

    sysopen my $fh, $path, O_WRONLY | O_CREAT | O_EXCL, 0600
        or croak "Cannot create temporary file '$path': $!";
    binmode $fh, ':raw';
    print {$fh} $text or croak "Cannot write temporary file '$path': $!";
    close $fh         or croak "Cannot write temporary file '$path': $!";

    my $status = system(@$editor, $path);
    croak "Editor (" . join(' ', @$editor) . ") " . _wait_status($status)
        . "; '$file' is unchanged"
        if $status != 0;

    my $edited = _read_file($path, 'edited file');

    return undef if $edited eq $text;
    return $edited;
}

# What system() reported, in words. $? is the wait status, not an exit code.
sub _wait_status {
    my ($status) = @_;

    return "could not be run: $!"      if $status == -1;
    return "was killed by signal " . ($status & 127) if $status & 127;
    return "exited with status " . ($status >> 8);
}

# The top-level `sops` key is reserved for the metadata section, and there is
# no way to encrypt a document that already uses it: serialization assigns the
# metadata into that key unconditionally, so the user's value is overwritten --
# after the digest has already covered it, which leaves a document that fails
# its own MAC on the very next read.
#
# sops refuses the same thing, before encrypting anything, with exit code 203:
#
#   The file you have provided contains a top-level entry called 'sops' [...]
#   SOPS uses a top-level entry called 'sops' to store the metadata required to
#   decrypt the file. For this reason, SOPS can not encrypt files that already
#   contain such an entry.
#
# It makes no distinction between "already encrypted" and "a user key that
# happens to be called sops" -- and neither do we, because from the outside
# they are the same document.
#
# The advice deliberately names NEITHER `edit` NOR `rotate`: the same guard
# fires from inside both (rotate via the encrypt() below, edit by the same
# path), and pointing the user at the method that just refused them is worse
# than not pointing at anything. The remedies are documented under those
# methods; the message here says what is wrong and what to do about it.
sub _sops_key_reserved {
    my ($what) = @_;
    return
        "$what contains a top-level 'sops' entry, which is reserved for the "
      . "SOPS metadata section. Encrypting would overwrite it and produce a "
      . "document that fails its own MAC verification. This usually means the "
      . "input is already encrypted -- decrypt it first if you want to change "
      . "its contents or re-key it. If it really is plaintext, rename the "
      . "entry. (sops refuses such a file too, with exit code 203.)";
}

# The same refusal for text that came back from an editor, which is a different
# situation with a different remedy: the document was just typed, nothing has
# been written yet, and pointing the user at edit -- which is where they
# already are -- would be no help at all.
#
# Both ways an edited document can carry the entry end here. See edit.
sub _edited_sops_key_reserved {
    my ($file) = @_;
    return
        "The edited document has a top-level 'sops' entry. That name is "
      . "reserved for the metadata section, which is written back "
      . "automatically -- remove it and edit again. '$file' is unchanged.";
}

# Is this exception the "top-level 'sops' entry is not a mapping" refusal?
#
# That refusal lives in File::SOPS::Metadata::from_hash, which the format
# handlers call from inside parse(), so a caller of parse() receives it as an
# exception -- indistinguishable, without this, from the document not parsing.
# edit is the only caller that has to tell the two apart.
#
# Keying on the message coupled this to another module's wording, deliberately
# and in preference to the alternatives: a syntax-only parse in the format
# handlers, or a typed exception, both reach well past the one call site that
# needs the distinction. t/17-in-place-and-edit.t pins both branches, so a
# rewording in Metadata.pm fails a test rather than quietly restoring the
# regression this replaced (k47) -- edit reporting a document that parses
# as one that does not.
sub _is_sops_not_a_mapping {
    my ($err) = @_;
    return defined $err && $err =~ /\Athe top-level 'sops' entry is\b/;
}

# Say WHERE something went wrong. A generic failure in a document of a hundred
# leaves costs an afternoon; the key path costs nothing to carry and is the
# only thing that makes the message actionable.
#
# The path is made of KEYS, which a SOPS document leaves readable by design.
# Nothing derived from the plaintext, the data key or an age identity is ever
# interpolated into an error -- an error message goes to logs and bug reports,
# and a value that leaks there was not encrypted for any practical purpose.
sub _at_path {
    my ($path, $err) = @_;
    my $where = ($path && @$path) ? join(':', @$path) : '(document root)';
    return "$where: " . _reason($err);
}

# An inner error's own text, without the file and line croak appended to it --
# the outer croak supplies a fresh one. Empty $@ becomes something readable
# rather than an empty pair of parentheses.
sub _reason {
    my ($err) = @_;
    return 'no reason given' unless defined $err && length $err;
    $err =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
    return length($err) ? $err : 'no reason given';
}

# The metadata a fresh encryption starts from. Only the encryption POLICY can
# be carried in from a caller: a new data key is about to be generated, so
# every wrapped copy of the old one, the MAC over the old values and the
# lastmodified that authenticates it are all regenerated regardless of what
# was handed over.
sub _metadata_for_encrypt {
    my ($args) = @_;

    my @given = grep { exists $args->{$_} } @File::SOPS::Metadata::ENCRYPTION_RULES;

    my %attr;
    if (defined(my $template = $args->{metadata})) {
        croak "metadata must be a File::SOPS::Metadata object"
            unless blessed($template)
                && $template->isa('File::SOPS::Metadata');

        %attr = $template->policy_args;

        # An explicit rule REPLACES the template's rather than joining it: the
        # rules are mutually exclusive, so merging the two could only ever
        # build a document sops refuses.
        delete @attr{@File::SOPS::Metadata::ENCRYPTION_RULES} if @given;
    }

    $attr{$_} = $args->{$_} for @given;
    $attr{mac_only_encrypted} = $args->{mac_only_encrypted}
        if defined $args->{mac_only_encrypted};

    my $metadata = File::SOPS::Metadata->new(%attr);
    _assert_rules_supported($metadata);

    return $metadata;
}

# Refuse to WRITE a document under a rule we cannot apply. Writing under a rule
# we ignore would leave values in plaintext that the rule says to encrypt, or
# the reverse, in a file that looks perfectly well-formed.
#
# Reading such a document is a SEPARATE question and is answered separately --
# decryption has been rule-driven since docs/adr/0049, so the rule is consulted
# there too, and where sops's own answer is reproducible the read path
# reproduces it rather than refusing. docs/adr/0051 is why the regex half of
# this lives behind a method of its own instead of inside the match.
sub _assert_rules_supported {
    my ($metadata) = @_;

    for my $rule (@File::SOPS::Metadata::UNSUPPORTED_ENCRYPTION_RULES) {
        my $value = $metadata->rule_value($rule);
        next unless defined $value && length $value;
        croak "Refusing to encrypt under '$rule': it selects values by their "
            . "comment, and neither of this distribution's parsers keeps "
            . "comments, so every value would be classified wrongly. Use the "
            . "sops CLI for documents that use it.";
    }

    # Asked HERE, once, rather than at the point of match. At the point of
    # match it fired from inside the leaf walk, so `encrypt` reported a rule
    # problem under whichever leaf the walk happened to reach first --
    # `bar: Cannot use '(?=f)foo' as the unencrypted_regex ...`, where `bar`
    # has nothing to do with it (k166). It is also the whole of what makes
    # the read path free to answer differently.
    $metadata->assert_rule_regexes_agree;

    return 1;
}

# age is the only backend implemented here, so a document holding key material
# for another one cannot be re-keyed: the new data key can be wrapped for its
# age recipients and for nobody else. Both ways out of that are wrong, and the
# quiet one is the worse -- dropping the entries revokes those recipients'
# access while reporting success, and keeping them leaves a wrapped copy of a
# key that no longer decrypts anything, which fails later and further away.
#
# Every operation that generates a new data key has to ask this, which is
# rotate and edit; the wording differs only in the verb.
sub _assert_rekeyable {
    my ($metadata, $file, %words) = @_;

    my @foreign = grep { $_ ne 'age' } $metadata->key_material_fields;
    return 1 unless @foreign;

    croak "Refusing to $words{verb} '$file': its sops section holds key material "
        . "this distribution cannot re-encrypt (" . join(', ', @foreign) . "). "
        . "$words{noun} generates a new data key, so those entries would be "
        . "silently dropped and the recipients behind them would lose access. "
        . "\u$words{verb} this file with the sops CLI, or, if losing them is "
        . "what you want, say so explicitly with decrypt followed by encrypt.";
}

# --- how deep a document may be -----------------------------------------
#
# Every walk in this file recurses, and each of them carries the two lines
# below: `no warnings 'recursion'` and a depth it refuses to pass. The two
# belong together and neither works alone.
#
# Perl warns "Deep recursion on subroutine" once a sub is 100 frames deep. That
# threshold is fixed and is about perl, not about the document: a 265-level
# document sops accepts is ordinary input here, and it produced 505 warning
# lines and 63 KB on STDERR for a correct encrypt (measured, k117) -- a
# successful operation that reads like a crash. The warning is silenced where
# it is noise, per walk rather than per file, so nothing outside these walks
# loses it.
#
# What the warning was also doing -- being the only thing that ever said a walk
# had lost its footing -- is replaced here by a bound that is part of the
# contract instead of a side effect of perl's stack accounting.
#
# The number is sops's, not ours, measured against sops 3.13.3 on documents
# built as `a: {a: {a: ... }}` and `a: [[[ ... ]]]`, counting CONTAINERS from
# the document's own root mapping:
#
#   go-yaml (sops -e, sops -d)  10001 accepted, 10002 refused
#                               "yaml: exceeded max depth of 10000"
#   encoding/json (sops -e)     10000 accepted, 10001 refused
#                               "invalid character '{' exceeded max depth"
#
# and, as with the cycle and the alias bomb, the -d refusal comes out AHEAD of
# the key: the same over-deep encrypted file with no age identity available
# still reports the depth.
#
# 10000 is therefore the deepest a document can be and still be readable in
# BOTH formats, and that is the number here. It is one level tighter than
# go-yaml alone on the YAML side, deliberately: the alternative is writing a
# JSON file that sops cannot read back, and refusing loudly is the cheaper of
# the two errors. It is the same shape of decision as docs/adr/0027 -- take the
# reference's own limit rather than invent one -- and the same reason.
#
# The bound is only a bound if reaching it is affordable, which is why the
# walks below carry the path as ONE array that is pushed and popped rather than
# copying it per level. Copying made a walk quadratic in depth: 4000 levels
# took 101s and 410 MB in _sorted_leaves alone, so a refusal at 10000 would
# have arrived minutes and gigabytes later -- a hang with a message attached.
# Shared and unwound, the same walk reaches 10000 in 17ms and 24 MB (measured).
#
# It is a variable and not a constant on purpose, and t/41 is the reason. That
# file bounds a runaway walk -- k110's, a document that contains itself --
# by dying at a depth no fixture of its own reaches, and until now it borrowed
# perl's fixed threshold of 100 for that. It cannot borrow it any more, because
# the line above silences it. So the bound it borrows instead is this one, and
# a caller reading untrusted documents can use it the same way. Lowering it
# refuses deep documents earlier than sops does; raising it writes documents
# sops will not read.
our $MAX_DEPTH = 10_000;

sub _assert_depth {
    my ($depth) = @_;

    return 1 if $depth <= $MAX_DEPTH;

    croak "this document nests containers more than $MAX_DEPTH deep, which is "
        . "as deep as this library walks. sops stops as well: go-yaml refuses "
        . "past 10001 nested containers with \"yaml: exceeded max depth of "
        . "10000\", and Go's JSON encoder past 10000 with \"exceeded max "
        . "depth\" -- in both directions, and ahead of the data key. The path "
        . "is not named here because it is thousands of keys long.";
}

# A container that is its own ancestor has no finite set of values, so there is
# nothing to encrypt, nothing to hash and no document to write. Nothing
# upstream of here stops one: the two YAML parsers this library uses disagree
# about it, YAML::XS building the cycle and handing it over while YAML::PP
# refuses the alias outright. So Format::YAML->parse returns a live Perl cycle,
# and every walk below it -- _sorted_leaves, _encrypt_tree, _decrypt_tree,
# _document_leaves -- recursed until the process was killed. A hang tells the
# caller nothing, cannot be caught, and where the document came from outside is
# resource exhaustion by a file. See k110 and docs/adr/0025.
#
# Refusing is what the reference implementation does, in BOTH directions.
# Measured against sops 3.13.3 on `root: &a` / `  b: *a`:
#
#   sops -e -> Error unmarshalling file: yaml: anchor 'a' value contains itself
#              (exit 2)
#   sops -d -> yaml: anchor 'a' value contains itself   (exit 1)
#
# and the -d refusal comes out AHEAD of the key error -- the same document with
# no age identity available still reports the cycle, not "Failed to get the
# data key" -- which is why the decrypt side asks this before unwrapping the
# data key rather than after.
#
# Terminating is not on its own an answer, which is why there is no visited set
# in the walks instead. A walk that skipped the second visit would emit a
# document with the alias expanded once and a digest taken over a tree that is
# not the one the file describes: a wrong answer, quietly, which is the defect
# class this layer keeps producing.
#
# The check is an ANCESTOR set, not a visited set, and that difference is the
# whole guard. A plain visited set would also refuse a shared but ACYCLIC
# subtree -- what an ordinary, non-recursive anchor builds -- and sops accepts
# those and expands them: measured, `base: &b` / `  p: 1` / `other: *b`
# encrypts to two independent ENC values and decrypts back to both. $active
# holds the current path and is unwound on the way back up; $clean holds the
# nodes already proven acyclic, so a diamond is walked once rather than once
# per path through it.
sub _assert_acyclic {
    no warnings 'recursion';
    my ($node, $path, $active, $clean, $depth) = @_;

    return 1 unless ref $node eq 'HASH' || ref $node eq 'ARRAY';

    # $clean makes this walk O(nodes) rather than O(paths), and that memo also
    # means the depth counted here is the depth of the FIRST path to a shared
    # subtree, not the deepest. It is not the only place the bound is asked:
    # the walks that expand aliases rather than memoising them -- _sorted_leaves,
    # _encrypt_tree, _decrypt_tree -- see the deeper path and refuse it there.
    $depth = ($depth // 0) + 1;
    _assert_depth($depth);

    my $addr = refaddr($node);
    return 1 if $clean->{$addr};

    croak _at_path($path, "this value contains itself, so the document has no "
        . "finite set of values to encrypt or to hash. A YAML anchor nested "
        . "inside its own value produces one, and so does a Perl structure "
        . "passed to encrypt that refers back to itself. sops refuses the same "
        . "document: \"yaml: anchor 'a' value contains itself\". An anchor that "
        . "is merely reused is fine and is not this.")
        if $active->{$addr};

    $active->{$addr} = 1;

    if (ref $node eq 'HASH') {
        # One path array, pushed and popped, not a copy per level: see the
        # depth comment above for what the copy cost at depth.
        for my $k (sort keys %$node) {
            push @$path, $k;
            _assert_acyclic($node->{$k}, $path, $active, $clean, $depth);
            pop @$path;
        }
    }
    else {
        # An array contributes no path component anywhere else in this library
        # and does not gain one here just because this path is a diagnostic.
        _assert_acyclic($_, $path, $active, $clean, $depth) for @$node;
    }

    delete $active->{$addr};
    $clean->{$addr} = 1;

    return 1;
}

# An acyclic document can still have no finite walk to it. Aliases that are
# merely SHARED, not recursive, expand into a tree with 2**N leaves, so
# _assert_acyclic above correctly does not fire -- the document really is
# acyclic -- and every walk below it explodes anyway. Measured at 25 levels,
# 727 bytes of YAML: encrypt_file did not return, and the walk climbs about a
# gigabyte of RSS every three seconds. See k112 and docs/adr/0027.
#
# The blowup is entirely ours. YAML::XS resolves an alias to the SAME Perl
# reference rather than to a copy, so Load returns a linear DAG -- 200 levels
# in 0.7ms -- and only _sorted_leaves, _encrypt_tree and _decrypt_tree expand
# it. There is therefore nothing to catch at parse time and nothing to
# pre-filter on the raw bytes; the guard belongs here, next to the other one,
# where it also covers the origin that has no parser at all: a caller handing
# encrypt the same hash reference from several places.
#
# Refusing is what the reference implementation does, in BOTH directions.
# Measured against sops 3.13.3:
#
#   sops -e -> Error unmarshalling file: yaml: document contains excessive
#              aliasing                                            (exit 2)
#   sops -d -> yaml: document contains excessive aliasing          (exit 1)
#
# and, as with the cycle, the -d refusal comes out ahead of the key error.
#
# go-yaml's budget is a RATIO, not a count, and that distinction is the whole
# guard. Bisected against the binary in four differently shaped families, it
# accepts a 206,104-node expansion and refuses an 8,146-node one: what it
# measures is how far the expansion exceeds the document that produced it.
# A cap on expanded nodes would therefore refuse files sops accepts, which is
# the one error this layer must not make. So the counters below are go-yaml's
# counters, in go-yaml's units, and the constants are its constants.
my $ALIAS_RATIO_RANGE_LOW  = 400_000;
my $ALIAS_RATIO_RANGE_HIGH = 4_000_000;

# The expansion is exponential, so its count overflows a double long before it
# overflows patience. Saturating keeps the arithmetic exact where it matters:
# past the high range the allowance is a flat 0.10 and nothing above the
# ceiling can change an answer.
my $EXPANSION_CEILING = 1_000_000_000;

sub _allowed_alias_ratio {
    my ($decoded) = @_;

    return 0.99 if $decoded <= $ALIAS_RATIO_RANGE_LOW;
    return 0.10 if $decoded >= $ALIAS_RATIO_RANGE_HIGH;
    return 0.99 - 0.89 * (($decoded - $ALIAS_RATIO_RANGE_LOW)
        / ($ALIAS_RATIO_RANGE_HIGH - $ALIAS_RATIO_RANGE_LOW));
}

# Returns the expanded node count and the expanded CONTAINER count for $node,
# and accumulates the written document's own shape in $written. Memoised on
# refaddr, which is what makes it O(distinct nodes) on a DAG whose expansion is
# exponential -- the same reason _assert_acyclic keeps a $clean set. The memo
# is not a cycle guard: it is filled on the way OUT, so a cycle would recurse
# forever here. _assert_acyclic runs first and that ordering is load-bearing.
sub _expansion_census {
    no warnings 'recursion';
    my ($node, $memo, $written, $depth) = @_;

    return (1, 0) unless ref $node eq 'HASH' || ref $node eq 'ARRAY';

    $depth = ($depth // 0) + 1;
    _assert_depth($depth);

    my $addr = refaddr($node);
    return @{$memo->{$addr}} if $memo->{$addr};

    $written->{containers}++;

    my ($nodes, $containers) = (1, 1);
    my @children;
    if (ref $node eq 'HASH') {
        # go-yaml decodes a mapping key as a node in its own right, so this
        # counts one too. The units have to be its units or the ratio is not
        # its ratio. A sequence has no keys and gains nothing here.
        my $keys = scalar keys %$node;
        $written->{keys} += $keys;
        $nodes += $keys;
        @children = values %$node;
    }
    else {
        @children = @$node;
    }

    for my $child (@children) {
        if (ref $child eq 'HASH' || ref $child eq 'ARRAY') {
            $written->{edges}++;
        }
        else {
            $written->{leaves}++;
        }
        my ($child_nodes, $child_containers)
            = _expansion_census($child, $memo, $written, $depth);
        $nodes      += $child_nodes;
        $containers += $child_containers;
        $nodes      = $EXPANSION_CEILING if $nodes > $EXPANSION_CEILING;
        $containers = $EXPANSION_CEILING if $containers > $EXPANSION_CEILING;
    }

    $memo->{$addr} = [$nodes, $containers];
    return ($nodes, $containers);
}

sub _assert_expansion_bounded {
    my ($node) = @_;

    my %written = (containers => 0, keys => 0, leaves => 0, edges => 0);
    my ($nodes, $containers) = _expansion_census($node, {}, \%written);

    # go-yaml's decodeCount: every node of the EXPANDED tree, plus the alias
    # node it passes through on the way into each repeated container. Every
    # expanded container but the root arrives through exactly one edge, and
    # exactly $written{containers} - 1 of those edges are anchor definitions
    # rather than aliases. Plus one for the document node itself.
    my $decoded = $nodes + $containers - $written{containers} + 1;
    $decoded = $EXPANSION_CEILING if $decoded > $EXPANSION_CEILING;

    # go-yaml's non-alias count: the document as WRITTEN -- the document node,
    # every distinct container, its keys and its scalar values, and one alias
    # node for each reference beyond a container's own definition.
    my $as_written = 1 + $written{containers} + $written{keys}
        + $written{leaves} + ($written{edges} - ($written{containers} - 1));

    my $aliased = $decoded - $as_written;

    return 1 unless $aliased > 100
        && $decoded > 1000
        && $aliased / $decoded > _allowed_alias_ratio($decoded);

    croak "this document expands to " . $decoded . " values from the "
        . $as_written . " it holds, which is the alias bomb sops refuses: "
        . "\"yaml: document contains excessive aliasing\". A YAML anchor "
        . "referenced from inside another anchor's value doubles the document "
        . "at every level, and a structure passed to encrypt that holds one "
        . "reference in several places does the same with no YAML involved. "
        . "Reusing an anchor is ordinary and is not this: sops allows an "
        . "expansion of up to 100 times what the document holds -- less as "
        . "the expansion itself grows past 400000 values -- and refuses this "
        . "one at " . sprintf('%.0f', $decoded / $as_written) . " times.";
}

sub _encryption_options {
    my ($args) = @_;
    return map { $_ => $args->{$_} }
        grep { exists $args->{$_} } @ENCRYPTION_OPTIONS;
}

###############################################################################
# THE COMMENT BUCKET, and it is a PATH rule rather than a name (docs/adr/0047)
#
# sops walks a branch with the branch's own path, and a comment is an ITEM of
# that branch whose key is Go's Comment struct -- so it contributes NO path
# component where an ordinary key does. Measured against sops 3.13.3: a comment
# inside an ini section `[db]` authenticates under `db:`, never `db::`, and
# `db::` is what a genuine empty key nested in a mapping authenticates under.
#
# The two are the same thing only where the branch is the document ROOT: there
# Go's join produces `:`, which _path_to_aad spells `['']`, and that is why
# File::SOPS::Format::ENV can keep a dotenv document's comments under a real,
# empty KEY. Format::INI's branches are sections and cannot.
#
# So: a `''` key whose value is a sequence of COMMENTS adds no path component
# when the path is already non-empty. Deliberately narrow --
#
#   * `@$path` non-empty, so the dotenv bucket at the root keeps the `''`
#     component it needs and nothing about that format moves;
#   * the value must be a non-empty ARRAY of comments, so `{ map => { '' =>
#     'v' } }` keeps `map::`, which is the AAD sops gives it, measured.
#
# The one shape whose AAD moves is a mapping key `''` holding a list of nothing
# but comments, below the top level. It is a shape sops cannot write, and THAT
# -- not agreement -- is what makes the rule safe. Measured on 3.13.3: where a
# genuine empty key holds a list carrying a comment AND a value, sops
# authenticates the comment under `db::`, so the rule must not fire there, and
# the all-comments test is exactly what keeps it from firing. A list of nothing
# but comments never comes back out of sops, because a comment leaf exists only
# where a node follows it in the same sequence -- measured over head, trailing,
# consecutive and lone comments: every sequence sops wrote held at least one
# non-comment element, and a comment with no node to attach to was hoisted to
# the parent branch or dropped. A document that trips this rule was therefore
# built by a caller by hand, and there we diverge from sops deliberately: the
# two readings of `''` are the same bytes on the wire, so nothing at this layer
# can tell them apart.
###############################################################################
our $COMMENT_BUCKET_KEY = '';

# Two shapes for a comment leaf, both load-bearing for the bucket predicate:
#
#   * a File::SOPS::Comment object -- the plaintext tree's spelling;
#   * a plain string whose text parses as ENC[...,type:comment] -- the wire
#     tree's spelling, and what decrypt returns at a path the encryption
#     rule EXCLUDES (rule-first decrypt, ADR 0049).
#
# Both have to answer YES here, for the same reason: the walks agree about
# the path they build. Where the bucket predicate returns NO the bucket key
# ADDS a path component, and the two walks answer `should_encrypt_path`
# about different paths. A plain value at `db:` is one AAD; the same value
# at `db::` (the bucket key appended) is another. The leaf walks don't
# share the bucket predicate -- one sub rather than two -- because a path
# they disagree on writes a document this library writes and then cannot
# read (measured, with `^$`: rotate declined a file encrypt had just
# written). The Comment-object half is recognised by _is_comment_leaf
# regardless of the data-key gate; the wire half is recognised by the same
# predicate k168 added to the leaf guard -- `!ref && encrypted_type
# eq 'comment'` -- which the data-key gate does not need because the
# predicate never decrypts. docs/adr/0059, k172.
sub _is_comment_bucket {
    my ($value) = @_;

    return 0 unless ref $value eq 'ARRAY' && @$value;
    for my $item (@$value) {
        next if File::SOPS::Encrypted->is_comment($item);
        next if !ref $item
            && (File::SOPS::Encrypted->encrypted_type($item) // '')
                eq 'comment';
        return 0;
    }
    return 1;
}

# THE predicate, asked by every walk that builds a path -- _encrypt_tree and
# _decrypt_tree. One sub rather than the same three lines twice over: since
# docs/adr/0049 both walks ask the encryption rule about the path they build,
# so a component one of them adds and the other does not is a document this
# library writes and then cannot read. The rule decides which AAD a value is
# encrypted under and which path the encryption rules are asked about, and a
# walk that answers it differently from _encrypt_tree produces a document this
# library writes and then refuses (measured, with unencrypted_regex `^$`:
# rotate declined a file encrypt had just written).
sub _adds_no_path_component {
    my ($key, $path, $value, $on_the_wire) = @_;

    return $key eq $COMMENT_BUCKET_KEY
        && @$path
        && _is_comment_bucket($value);
}

sub _encrypt_tree {
    no warnings 'recursion';
    my ($node, $key, $metadata, $path, $depth) = @_;

    $depth = ($depth // 0) + 1;
    _assert_depth($depth) if ref $node eq 'HASH' || ref $node eq 'ARRAY';

    if (ref $node eq 'HASH') {
        my %result;
        for my $k (keys %$node) {
            # The walk descends unconditionally and the rules are applied at
            # the leaf, against the WHOLE path. Deciding per level and
            # skipping the subtree is the same answer for the unencrypted
            # rules -- an excluded branch stays excluded all the way down --
            # but not for the encrypted ones, where the reference
            # implementation encrypts a leaf as soon as SOME component of its
            # path matches. Measured against sops 3.13.3 with
            # --encrypted-suffix _enc: everything under a `top_enc:` block is
            # encrypted, and a `nested_enc:` under a plain parent is too.
            # docs/adr/0047: the comment bucket is the branch itself, so it
            # adds no path component. See $COMMENT_BUCKET_KEY above.
            my $bucket = _adds_no_path_component($k, $path, $node->{$k});
            push @$path, $k unless $bucket;
            # A comment is a SEQUENCE entry or nothing. sops attaches a comment
            # to the node that follows it, so above a mapping key it stays a
            # comment LINE and no store writes one into a mapping value slot.
            # Measured against sops 3.13.3 with this guard lifted: the document
            # is read at exit 0 and the key comes back holding Go's yaml.Comment
            # struct -- `value:` and `inline:` under the key, where the caller
            # meant a comment. Silent, and in a file this library wrote. The
            # twin of the check in _decrypt_tree; see docs/adr/0041.
            croak _at_path($path, "a comment cannot be a mapping value. sops "
                . "attaches a comment to the node that FOLLOWS it, so the only "
                . "place a SOPS document holds one as a leaf is a sequence "
                . "entry -- above a mapping key it is a comment LINE, which no "
                . "emitter here can write. Written into this slot the document "
                . "would still be read by sops at exit 0, with the key holding "
                . "a dump of Go's comment struct instead of a value (measured "
                . "against sops 3.13.3). Put the comment in a list, or leave it "
                . "out")
                if File::SOPS::Encrypted->is_comment($node->{$k});
            $result{$k} = _encrypt_tree($node->{$k}, $key, $metadata, $path,
                $depth);
            pop @$path unless $bucket;
        }
        return \%result;
    }
    elsif (ref $node eq 'ARRAY') {
        # A wire-bucket of ENC[...,type:comment] strings must NOT descend into
        # the list -- the leaf code path would fire k168 on every item
        # the rule EXCLUDES (because each item is a plain string whose text
        # spells an ENC-comment token), and at any path it would re-encrypt
        # the token as a plain type:str and lose the comment label. Both
        # halves of that break a comment line this library previously wrote,
        # so the walk returns the bucket list as-is. The Comment-object half
        # is intentionally NOT in scope here: a Comment object at a SELECTED
        # path still descends so the walk can encrypt it, which is what
        # makes the round trip produce ENC-comment strings on the way out.
        # docs/adr/0059, k172.
        my $is_wire_bucket = 1;
        for my $item (@$node) {
            if (ref $item
                || (File::SOPS::Encrypted->encrypted_type($item) // '')
                    ne 'comment') {
                $is_wire_bucket = 0;
                last;
            }
        }
        return $node if $is_wire_bucket;
        my @result;
        for my $item (@$node) {
            # SOPS does NOT add array index to path - all array elements share parent's path
            push @result, _encrypt_tree($item, $key, $metadata, $path, $depth);
        }
        return \@result;
    }
    else {
        # A leaf the rules exclude is written as it stands. It is still
        # covered by the MAC, so it is readable but authenticated.
        #
        # EXCEPT a leaf whose text parses as ENC[...,type:comment]: the
        # encrypt side writes it as a plain type:str and hashes its text
        # into the digest, but on the read side _is_comment_leaf (with
        # $data_key defined) treats the same text as a comment and drops
        # it from the digest -- a document that fails its own MAC, produced
        # by this library at exit 0. The File::SOPS::Comment half of the
        # same shape is caught by the mapping-loop guard above (ADR 0041);
        # this one is the wire half, reached because the caller passed a
        # plain string rather than a Comment object. docs/adr/0056,
        # k168.
        croak _at_path($path, "a caller string whose text parses as an "
            . "ENC[...,type:comment] token cannot stand as a value at a "
            . "path the encryption rule EXCLUDES: this library writes the "
            . "literal as a plain type:str and hashes its text into the "
            . "MAC, but the read side (_is_comment_leaf with \$data_key "
            . "defined) drops the same text from the digest, so the "
            . "document fails its own MAC at the next decrypt. sops reads "
            . "the document but ignores the leaf at the same level -- "
            . "which is why the symptom on decrypt is 'Authentication "
            . "failed' rather than 'MAC mismatch'. Replace the string "
            . "with a File::SOPS::Comment in a SEQUENCE position, or "
            . "rename the key so the rule no longer excludes it")
            if !$metadata->should_encrypt_path($path)
                && !ref $node
                && (File::SOPS::Encrypted->encrypted_type($node) // '')
                   eq 'comment';

        return $node unless $metadata->should_encrypt_path($path);

        # Leaf value - encrypt it
        # SOPS doesn't encrypt empty values; they stay in the document AS THEY
        # ARE. A null stays a null and an empty string stays an empty string.
        # Returning '' for both turned every null in the input into an empty
        # string, where sops leaves a null alone in YAML and in JSON alike
        # (measured: `a: null` comes back out of `sops -d` as `a: null`). The
        # digest does not notice, because Go hashes a nil as nothing and so do
        # we -- but the value the caller stored came back changed, which is the
        # one thing this library exists not to do.
        #
        # The !blessed() guard is load-bearing: JSON::PP::Boolean overloads eq,
        # and JSON->false eq '' is TRUE (while it stringifies to '0'). Without
        # the guard every false boolean was skipped here and written to the file
        # as a plaintext '', after _compute_mac had already hashed 'False' --
        # so the document failed its own MAC check on the next read. sops
        # encrypts false as type:bool with plaintext 'False'.
        #
        # The type check is the same rule for the other false boolean, which is
        # NOT blessed and so walks straight past that guard: Perl's own boolean
        # SV (!!0, $x > 9, builtin::false), whose PV really is the empty string.
        # Same defect, same symptom -- a plaintext '' in the document against a
        # digest of 'False', sops -d exit 51 -- and it went unnoticed because
        # k90 was filed from the unencrypted slot. The eq runs first, so
        # the type ladder is consulted only for a leaf that does stringify
        # empty. See docs/adr/0016.
        return undef if !defined $node;
        return ''    if !blessed($node) && $node eq ''
                     && File::SOPS::Encrypted->detect_type($node) ne 'bool';

        my $aad = _path_to_aad($path);
        my $enc = eval {
            File::SOPS::Encrypted->encrypt_value(
                value => $node,
                key   => $key,
                aad   => $aad,
            );
        } or croak _at_path($path, $@);
        return $enc->to_string;
    }
}

sub _decrypt_tree {
    no warnings 'recursion';
    my ($node, $key, $metadata, $path, $depth) = @_;

    $depth = ($depth // 0) + 1;
    _assert_depth($depth) if ref $node eq 'HASH' || ref $node eq 'ARRAY';

    if (ref $node eq 'HASH') {
        my %result;
        for my $k (keys %$node) {
            # docs/adr/0047, the read-side twin of the rule in _encrypt_tree.
            # $key IS the data key here, so a bucket of ENC[...,type:comment]
            # strings is recognised as one.
            my $bucket = _adds_no_path_component($k, $path, $node->{$k}, $key);
            push @$path, $k unless $bucket;
            # The read-side twin of _encrypt_tree's guard, and the whole of what
            # is left of docs/adr/0024's refusal. A comment leaf in a SEQUENCE
            # is read and kept (that is the only shape any sops store writes);
            # one in a mapping VALUE slot is a document no store produces, and
            # sops reads it as a dump of Go's comment struct rather than as a
            # value. Refused here rather than in a format handler because it is
            # not a format's rule -- the same document is read through the JSON
            # handler, which had no such guard at all. docs/adr/0041.
            croak _at_path($path, "this document holds a sops comment "
                . "(type:comment) as a mapping value, which is not a shape any "
                . "SOPS store writes: a comment is attached to the node that "
                . "FOLLOWS it, so above a mapping key it stays a comment LINE "
                . "and only a comment above a SEQUENCE entry becomes a leaf. "
                . "Read with sops this leaf does not come back as a value "
                . "either -- it comes back as a dump of Go's comment struct. "
                . "Remove it from the document, or read the file with sops")
                if !ref $node->{$k}
                && (File::SOPS::Encrypted->encrypted_type($node->{$k}) // '')
                   eq 'comment';
            $result{$k} = _decrypt_tree($node->{$k}, $key, $metadata, $path,
                $depth);
            pop @$path unless $bucket;
        }
        return \%result;
    }
    elsif (ref $node eq 'ARRAY') {
        my @result;
        for my $item (@$node) {
            # SOPS does NOT add array index to path - all array elements share parent's path
            push @result, _decrypt_tree($item, $key, $metadata, $path, $depth);
        }
        return \@result;
    }
    else {
        # RULE-FIRST, which is how sops reads a document: the rule decides
        # what a leaf IS, and the leaf's own text never gets a vote. An
        # excluded leaf is a literal value whatever it spells -- ENC[...]
        # included -- and the digest sees that text, which is what
        # _mac_bytes and _digested_leaves below had to learn with it.
        #
        # Asking the LEAF instead is what let rotate and edit write an
        # excluded value's plaintext back into the file at exit 0 (k150),
        # which docs/adr/0046 closed with a guard on the write path and handed
        # the mechanism here. Measured on sops 3.13.3 over 4 formats x 4 rule
        # fields x 4 cells, all 64 answering alike: an ENC[...] leaf the rule
        # excludes is exit 51 (its own text is in the digest -- read straight
        # off sops's `computed` figure), and a bare leaf the rule selects is
        # exit 25. docs/adr/0049.
        return $node unless $metadata->should_encrypt_path($path);

        # A SELECTED slot holds an encrypted string, and sops leaves exactly
        # four shapes alone there rather than refusing them (measured in all
        # four formats, exit 0 each):
        #
        #   * a null -- Go's walk returns before the cipher is reached;
        #   * an empty string -- the cipher itself short-circuits it;
        #   * a comment, which sops warns about and keeps;
        #   * an empty list or mapping, which holds no leaf and never arrives.
        #
        # The first two are the only shapes _encrypt_tree writes bare into a
        # selected slot, so they are also what keeps a document THIS library
        # wrote readable. !ref guards the eq: JSON::PP::Boolean overloads it
        # and JSON->false eq '' is true.
        return $node if !defined $node;
        return $node if !ref $node && $node eq '';
        if (File::SOPS::Encrypted->is_comment($node)) {
            # A PLAINTEXT comment stands in a slot the rule ENCRYPTS. sops keeps
            # it at exit 0 -- one of the four bare shapes above -- but it also
            # warns, because a comment in an encrypted slot can hold a secret in
            # the clear and there is nothing to authenticate it. Measured on
            # sops 3.13.3 (yaml, ini, dotenv): warning on the DECRYPT path only,
            # `Found possibly unencrypted comment in file`; the encrypt path
            # encrypts it into a type:comment leaf and says nothing. This is the
            # decrypt path, so this is where the warning belongs. Advisory only:
            # nothing here moves -- the comment is returned unchanged and the MAC
            # walk never reaches this branch. docs/adr/0067; the carp precedent
            # is docs/adr/0018 and the OUTCOME (the comment is kept) is one of
            # docs/adr/0049's four exceptions. The comment TEXT is NOT quoted --
            # it may be the secret this warns about, and a value that leaks into
            # a log was not encrypted for any practical purpose.
            carp _at_path($path, "a plaintext comment stands in a slot this "
                . "document's encryption rule marks as encrypted. It is kept "
                . "as it stands, but it is not encrypted and not "
                . "authenticated, so it may hold a secret in the clear. sops "
                . "reads the same document at exit 0 and warns the same way "
                . "(measured against sops 3.13.3: `Found possibly unencrypted "
                . "comment in file`). Re-encrypting the document (rotate, edit, "
                . "encrypt_in_place, or decrypt_file plus encrypt_file) turns "
                . "the comment into an encrypted type:comment leaf");
            return $node;
        }

        # The other direction of the same disagreement, and the one sops's
        # walk reaches first: bare where the rule says encrypted. Read as a
        # literal it was silently ENCRYPTED by the next write -- a value that
        # was readable, turned into ciphertext under a key the caller may not
        # keep. sops stops at exit 25 with `Input string <value> does not
        # match sops' data format`; the value is NOT quoted here, because a
        # leaf that is bare where the rule says encrypted is a secret in the
        # clear and an error message goes to bug reports.
        croak _at_path($path, "this document's own encryption rule says this "
            . "value is encrypted, but the file holds it as a plain value, "
            . "so there is nothing here to decrypt. sops refuses the same "
            . "document rather than reading it (measured on 3.13.3: exit 25, "
            . "'Input string ... does not match sops' data format'), because "
            . "it decrypts rule-first. Correct the rule -- in the sops "
            . "section, or in the .sops.yaml the file was encrypted under -- "
            . "so that it matches the values that really are encrypted. Only "
            . "an empty value, a null and a comment may stand bare in an "
            . "encrypted slot")
            unless !ref $node && File::SOPS::Encrypted->is_encrypted($node);

        my $aad = _path_to_aad($path);
        my @value = eval {
            my $enc = File::SOPS::Encrypted->parse($node);
            (scalar $enc->decrypt_value(key => $key, aad => $aad));
        };
        croak _at_path($path, $@) if $@;
        return $value[0];
    }
}

sub _path_to_aad {
    my ($path) = @_;
    # Go builds the AAD as strings.Join(path, ":") + ":". An undef path is a
    # caller bug (the walks always pass an arrayref, possibly empty); answering
    # "" there keeps a missing argument from masking the bug as a quiet AAD
    # mismatch. An empty arrayref is the document ROOT, where Go answers ":"
    # and this routine answers ":" -- the join below produces it. The four
    # format handlers all build a non-empty path before they reach a leaf, so
    # the empty case is unreachable today, but a future format that walks the
    # root would land here and the answer has to match sops.
    return '' unless defined $path;
    # SOPS format: path components joined with ":" plus trailing ":"
    #
    # This is a CHARACTER string -- the components are keys straight out of the
    # parser. UTF-8 encoding it is File::SOPS::Encrypted's job, done once at the
    # cipher boundary (_utf8_bytes) so that encrypt_value, decrypt_bytes and the
    # MAC's decrypt_bytes call cannot drift apart on it. Do not encode here as
    # well; that would double-encode every non-ASCII key.
    return join(':', @$path) . ':';
}

# --- MAC ----------------------------------------------------------------
#
# The MAC is a SHA-512 over the plaintext of EVERY leaf in the document -- no
# keys, no paths -- uppercase hex, itself AES-GCM encrypted with lastmodified
# as AAD. Two things about it are easy to get wrong and impossible to notice
# from inside this library, because both sides of a self-produced file agree
# with each other while disagreeing with sops:
#
#   1. It covers unencrypted values too. Values excluded from encryption by
#      unencrypted_suffix (or any of the other rules) are hashed exactly like
#      encrypted ones. Only mac_only_encrypted changes that, and then the
#      digest additionally starts from a fixed 32-byte block so the two
#      settings can never collide.
#
#   2. It is order dependent, and the order is DOCUMENT order. The encrypt
#      side has only a Perl hash to walk, whose iteration order is randomized,
#      so it walks sorted -- which is correct precisely because both
#      serializers emit sorted keys (see t/05-format-key-order.t). The decrypt
#      side must reproduce whatever order the producer used, and for a file
#      written by sops that is the order of the original document, not sorted
#      order. Hence _document_leaves, which recovers key order from an
#      order-preserving reparse of the raw text.
#
# Both directions funnel into _mac_digest so the two rules above are stated
# once. What differs is only how the leaves are collected and what a leaf's
# bytes are.

# MACOnlyEncryptedInitialization, verbatim from sops.go.
our $MAC_ONLY_ENCRYPTED_INIT = pack 'C*',
    0x8a, 0x3f, 0xd2, 0xad, 0x54, 0xce, 0x66, 0x52,
    0x7b, 0x10, 0x34, 0xf3, 0xd1, 0x47, 0xbe, 0x0b,
    0x0b, 0x97, 0x5b, 0x3b, 0xf4, 0x4f, 0x72, 0xc6,
    0xfd, 0xad, 0xec, 0x81, 0x76, 0xf2, 0x7d, 0x69;

# The leaves the digest covers, which is not every leaf: a COMMENT is not a
# value, and sops hashes none of them. Measured against sops 3.13.3 in seven
# ways -- deleting a comment leaf from an encrypted file leaves `sops -d` at
# exit 0 in YAML, INI and ENV where deleting a value gives exit 51; three
# documents with identical values and different comments have byte-identical
# MAC plaintext; relabelling a type:str value to type:comment takes it OUT of
# what sops digests; and the digest taken here over four sops-written documents
# matches the one they store EXACTLY when the comment leaves are dropped, with
# --mac-only-encrypted and beside an _unencrypted subtree included.
#
# Applied to the collected leaves rather than inside _mac_digest, so that the
# representability sweep in _compute_mac and the leaf COUNT in the MAC error
# message speak about the same list the digest was taken over. See
# docs/adr/0041.
#
# Since docs/adr/0049 the wire half has a condition, and it is not tidiness:
# see _wire_comment_reads_as_a_comment below.
sub _digested_leaves {
    my ($leaves, $data_key, $metadata) = @_;
    return [ grep {
        my ($path, $value) = @$_;
        !_is_comment_leaf($value,
            _wire_comment_reads_as_a_comment($path, $data_key, $metadata)
                ? $data_key : undef);
    } @$leaves ];
}

# Whether an ENC[...,type:comment] string sitting at $path comes back out of
# the file as a COMMENT or as a value -- which is what decides whether the
# digest covers it, because sops digests no comment and does digest a value.
#
# It has two answers because the wire has two shapes for a comment, and only
# one of them is a value slot:
#
#   * In a FLAT store a comment is a comment LINE -- `#ENC[...]` in dotenv,
#     `; ENC[...]` in ini -- so the store reads it as a comment before any rule
#     is consulted, and no rule can turn it into a value. This handler's
#     spelling for such a line is the comment bucket, a `''` KEY, so a leaf
#     whose last path component is that key is a comment line whatever the rule
#     says. See $COMMENT_BUCKET_KEY and docs/adr/0045 / docs/adr/0047.
#   * In YAML a comment is an ordinary SEQUENCE ENTRY holding the ENC[...]
#     string, and it becomes a comment only where something decrypts it -- so
#     at a path the rule EXCLUDES it stays a string and is digested as one.
#
# Measured on sops 3.13.3, one rule-swapped document per format put through
# both hypotheses with the MAC recomputed each way (`sops -d` exit code):
#
#                     comment digested   comment skipped
#     yaml                    0                51
#     ini                    51                 0
#     dotenv                 51                 0
#
# The encrypt side has no data key and no wire shapes, and answers nothing
# here.
sub _wire_comment_reads_as_a_comment {
    my ($path, $data_key, $metadata) = @_;

    return 0 unless defined $data_key;
    return 1 if @$path && $path->[-1] eq $COMMENT_BUCKET_KEY;
    return !$metadata || $metadata->should_encrypt_path($path) ? 1 : 0;
}

# A comment wears two shapes and they are NOT one question. In a plaintext tree
# it is a File::SOPS::Comment; in the tree the FILE holds it is an
# ENC[...,type:comment] string. The wire half is read only where the tree really
# is the file's -- $data_key defined, which is the same discriminator _mac_bytes
# already decrypts under, and the decrypt side is the only side that has one.
#
# The gate is load-bearing rather than tidy. Without it, a caller's plain string
# that happens to spell ENC[...,type:comment] would be dropped from the digest
# here while _encrypt_tree writes it into the document as an ordinary type:str
# value -- a document that fails its own MAC, produced by this library, which is
# the exact defect class the one-conversion rule exists to prevent.
#
# The wire half decodes nothing (encrypted_type reads the one anchored regex),
# so a comment whose ciphertext is damaged still stays out of the digest --
# which is what sops does with one, measured.
sub _is_comment_leaf {
    my ($value, $data_key) = @_;

    return 1 if File::SOPS::Encrypted->is_comment($value);
    return 0 unless defined $data_key;
    return (File::SOPS::Encrypted->encrypted_type($value) // '') eq 'comment'
        ? 1 : 0;
}

sub _compute_mac {
    my ($data, $key, $metadata) = @_;

    # $data is one document tree today, and an ArrayRef of document trees once
    # the api lane assembles a multi-document write (docs/adr/0033, k31).
    # Each document contributes its leaves in its own sorted-key order, in
    # document order, and the digest is over the concatenation (measured: one
    # MAC over all documents in order). Each document is entered by its OWN
    # top-level _sorted_leaves call, so the document list is never walked as a
    # container and no document is charged a depth level for the wrapper
    # (docs/adr/0033 Decision 4). A single HashRef is [$data], byte-identical.
    my @documents = ref $data eq 'ARRAY' ? @$data : ($data);
    my @collected;
    push @collected, @{ _sorted_leaves($_, [], []) } for @documents;

    my $leaves = _digested_leaves(\@collected);

    # Every leaf this document will contain has to be one both implementations
    # can write and read back. Checked HERE, before anything is emitted,
    # because this is the only walk on the encrypt side that sees every leaf --
    # including the ones the encryption rules exclude, which reach the document
    # verbatim and are the case Go rejects hardest (a uint64 stops `sops -d`
    # outright in YAML and produces a MAC mismatch in JSON). Doing it in
    # encrypt_value would miss exactly those, and doing it in value_to_bytes
    # would also reject legitimate sops documents on the READ side, where the
    # same walk is used to verify.
    # THE SLOT goes with the leaf, because one of the questions
    # assert_representable answers depends on it: an ENCRYPTED slot's wire form
    # for a non-finite float is type:float and the plaintext Go's
    # strconv.FormatFloat writes, which is what `sops -e` produces in both
    # formats, while an UNENCRYPTED one has only the plain YAML token go-yaml
    # resolves -- and no token at all in JSON. This walk is where that
    # difference is knowable at all: the encryption rules live in the metadata,
    # and by the time the emitters run an encrypted leaf is an ENC[...] string.
    # The same predicate _encrypt_tree encrypts by, asked of the same path.
    # See docs/adr/0040 and k122.
    for my $leaf (@$leaves) {
        my ($path, $value) = @$leaf;
        eval { File::SOPS::Encrypted->assert_representable($value,
                   encrypted => $metadata->should_encrypt_path($path)); 1 }
            or croak _at_path($path, $@);
    }

    my $mac_value = _mac_digest(
        leaves   => $leaves,
        metadata => $metadata,
    );

    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => $mac_value,
        key   => $key,
        # AAD is the lastmodified timestamp in RFC3339 format
        aad   => $metadata->lastmodified // '',
        type  => 'str',
    );

    return $enc->to_string;
}

sub _verify_mac {
    my (%args) = @_;
    my $metadata = $args{metadata};
    my $data_key = $args{data_key};

    my $stored = $metadata->mac;
    croak "File has no MAC - refusing to return unverified data "
        . "(pass ignore_mac => 1 to override)"
        unless defined $stored && length $stored;

    # parse() now dies on a well-shaped ENC value whose base64 is not valid,
    # rather than decoding it to something shorter. Catch it here so the
    # message still says WHICH value was unreadable -- the sops section's mac,
    # not some leaf.
    my $mac_enc = eval { File::SOPS::Encrypted->parse($stored) };
    croak "Cannot parse MAC (" . _reason($@) . ") - refusing to return "
        . "unverified data (pass ignore_mac => 1 to override)"
        unless $mac_enc;

    my $expected = eval {
        $mac_enc->decrypt_bytes(key => $data_key, aad => $metadata->lastmodified // '')
    };
    croak "Cannot decrypt MAC - refusing to return unverified data "
        . "(pass ignore_mac => 1 to override)"
        unless defined $expected;

    # Document order where we can recover it, sorted order otherwise -- which
    # is the same thing for every file this library writes. Getting the order
    # wrong can only make verification fail, never wrongly succeed.
    #
    # The format class is the one that PARSED this document, passed in rather
    # than guessed, so the order and the values can never come from two
    # different readings of the same text.
    my $ordered = _parse_in_document_order($args{document}, $args{format_class});

    # $ordered is a HashRef for one document, an ArrayRef of ordered documents
    # for a stream (docs/adr/0033, k31), or undef when order could not be
    # recovered. $args{data} mirrors it: one tree today, a list of trees once
    # the api lane assembles a multi-document decrypt. The three shapes are
    # normalised to a leaf list here.
    my @data_docs = ref $args{data} eq 'ARRAY' ? @{$args{data}} : ($args{data});
    my @collected;
    if (ref $ordered eq 'ARRAY') {
        # Document order from the reparse, values from the tree, PAIRED BY
        # INDEX -- document i's order with document i's values, each in its own
        # key order. A count disagreement between the two readers means the
        # order cannot be trusted, so fall back to sorted (which can make
        # verification fail, never wrongly succeed) rather than mispair.
        if (@$ordered == @data_docs) {
            push @collected,
                @{ _document_leaves($ordered->[$_], $data_docs[$_], [], []) }
                for 0 .. $#$ordered;
        }
        else {
            $ordered = undef;
        }
    }
    elsif ($ordered) {
        # One document, byte-identical to the pre-multi-document path.
        @collected = @{ _document_leaves($ordered, $data_docs[0], [], []) };
    }

    unless (@collected || $ordered) {
        # No recoverable order: sorted-key order, each document walked by its
        # own top-level call so the list is never charged a wrapper depth level.
        push @collected, @{ _sorted_leaves($_, [], []) } for @data_docs;
    }

    my $leaves = _digested_leaves(\@collected, $data_key, $metadata);

    my $computed = _mac_digest(
        leaves   => $leaves,
        metadata => $metadata,
        data_key => $data_key,
    );

    # Say what was checked. Neither digest is printed: it is a SHA-512 over the
    # concatenated plaintexts of the whole document, and a document with one
    # short secret in it is brute-forceable from that hash. sops prints both;
    # we print the shape of the check instead, which is the part that tells you
    # where to look. Nothing here is derived from a value, a data key or an age
    # identity.
    # A HINT for documents this library refuses but sops wrote and sops -d
    # also refuses -- ENV and INI have no type label, so sops's display form
    # for a typed value lands in the file as bare bytes that disagree with
    # what the digest covers. The text alone is ambiguous with a string of
    # the same spelling (which sops -d reads at exit 0), so the hint is
    # phrased as "consistent with" rather than as a confirmed cause, and
    # not added for any other format. See docs/adr/0052 and k174.
    my $hint = _mac_failure_sops_display_hint($args{data}, $metadata, $args{format_class});

    # A second hedged hint for the sops-written bare `-0` case: any float
    # that underflows to negative zero on Go's side is written as `-0` (or
    # `-0.0`), and yaml.v3 / json.v2 read `-0` back as int 0, so the file
    # fails its own MAC and `sops -d` refuses it too. We never write this
    # shape (ADR 0014 ships `-0.0`), so the hint only fires for files
    # sops produced. Scans raw document text, not the parsed tree -- by
    # the time the tree is in hand the `-0` has become int 0 and the
    # signal is gone. See docs/adr/0063 and k121.
    if ($hint eq '') {
        $hint = _mac_failure_sops_negzero_hint($args{document}, $args{format_class});
    }

    croak sprintf(
        "MAC verification failed: the digest over %d leaf value%s in %s "
        . "order does not match the one stored in the sops section%s. The "
        . "document has been altered since it was written, or was written by "
        . "something that computes the digest differently.%s Pass ignore_mac "
        . "=> 1 to read it anyway -- what you get back is decrypted but not "
        . "authenticated.",
        scalar @$leaves,
        (@$leaves == 1 ? '' : 's'),
        ($ordered ? 'document' : 'sorted-key'),
        ($metadata->mac_only_encrypted ? ', with mac_only_encrypted set' : ''),
        ($hint ? ' ' . $hint : ''),
    ) unless $expected eq $computed;

    return 1;
}

# Hedged hint appended to the MAC verification refusal: when the format is
# untyped (env, ini) and a leaf carried in an UNENCRYPTED slot reads as one of
# the wire text spellings Go's printer writes for a typed value, the file is
# consistent with one sops wrote and `sops -d` also cannot open. Two
# qualifications make the wording a "consistent with" rather than a finding.
#
#   1. The text is AMBIGUOUS with a literal string of the same spelling -- the
#      string "true" and the bool true are byte-identical on the wire, and
#      a sops-write containing a string "true" in an unencrypted slot is read
#      back at exit 0. A hint that named this as the cause without that
#      qualification would misdiagnose those documents.
#   2. The check is on the PARSED tree the rest of the library is working
#      with, not on the document bytes -- a document whose wire form is a
#      display form but whose parser normalises it before _verify_mac can
#      see it (none of the four current handlers do this for env/ini) would
#      not match here. That is named, not fixed, because repairing the text
#      on read would change what a re-write emits (docs/adr/0052).
#
# Returns the empty string for every other format or shape. The walker is
# kept narrow on purpose: only what the detection rule in docs/adr/0052
# section 3 names.
sub _mac_failure_sops_display_hint {
    my ($data, $metadata, $format_class) = @_;

    return '' unless $format_class;
    # The real handlers all declare format_name; defensive check so a mock
    # handler in t/51 (LineFormat, ReversedLineFormat, DeclinesOrder) does
    # not change behaviour here.
    return '' unless $format_class->can('format_name');
    my $name = $format_class->format_name;
    return '' unless $name eq 'env' || $name eq 'ini';

    my $matches = [ _scan_sops_display_forms($data, $metadata, []) ];
    return '' unless @$matches;

    my ($path, $text) = @{$matches->[0]};
    my $where = @$path ? join(':', @$path) : '(document root)';

    return sprintf(
        'The document also carries an unencrypted value at %s whose text (%s) '
        . 'is a Go display form sops writes into an %s slot for a typed value '
        . '(bool, null, or float); the MAC covers the typed value rather than '
        . 'the displayed text, and `sops -d` rejects the same document. The '
        . 'text alone is ambiguous with a string of the same spelling -- '
        . 'which sops reads at exit 0 -- so this only indicates a consistent '
        . 'cause, not a confirmed one.',
        $where, $text, $name,
    );
}

# Hedged hint for the sops-written bare `-0` case (k121 / docs/adr/0063).
# Go's float printer writes any underflowed negative zero as the bare token
# `-0` (or `-0.0`); yaml.v3 and json.v2 read `-0` back as int 0, so the
# document fails its own MAC and `sops -d` reports exit 51. We never emit
# this shape (ADR 0014 ships `-0.0`), so the hint only fires for files sops
# produced -- the signal is in the document text, not the parsed tree (the
# tree has int 0 and the original sign is gone).
#
# Two qualifications keep the wording a "consistent with" rather than a
# finding, matching _mac_failure_sops_display_hint:
#
#   1. The regex matches the literal token `-0(\.0+)?` anywhere in the
#      document text. A user with a key named `lastoffset: -0` would match
#      the regex but for a different reason; the hint names the sops bug
#      without claiming it is the cause.
#   2. ENV and INI carry values as plain strings, so a bare `-0` there is
#      the string "-0" and the digest agrees with what gets read. Only
#      yaml and json have typed values, so only those formats can carry the
#      bug.
#
# Returns the empty string for every other format or shape.
sub _mac_failure_sops_negzero_hint {
    my ($document, $format_class) = @_;

    return '' unless $format_class && $format_class->can('format_name');
    my $name = $format_class->format_name;
    return '' unless $name eq 'yaml' || $name eq 'json';

    # The sops section itself does not carry this shape: age recipients are
    # base32, the mac is ENC[...], the lastmodified is ISO 8601, the version
    # is a dotted triplet, and base64 alphabet is A-Za-z0-9+/= (no `-`).
    # So a raw substring match over the whole document is safe.
    #
    # The lookahead (?![0-9.eE]) keeps a digit, a period, or an exponent
    # marker right after the candidate from being part of the same token:
    # -01, -0.5, -0e3, -0E3 are NOT the bug shape and must not match.
    # -0.0 / -0.00 / -0.000 all match (the .0+ repeat consumes every
    # trailing zero, then the lookahead sees a token boundary).
    return '' unless defined $document
        && $document =~ /-0(?:\.0+)*(?![0-9.eE])/;

    return 'The document also carries a bare `-0` token in an unencrypted '
         . 'value -- a known sops shape: any float that underflows to '
         . 'negative zero is written as `-0` but parses back as int 0, '
         . 'so the file fails its own MAC and `sops -d` also refuses it.';
}

sub _scan_sops_display_forms {
    my ($node, $metadata, $path) = @_;
    no warnings 'recursion';

    if (ref $node eq 'HASH') {
        my @found;
        for my $k (keys %$node) {
            push @$path, $k;
            push @found, _scan_sops_display_forms($node->{$k}, $metadata, $path);
            pop @$path;
        }
        return @found;
    }
    if (ref $node eq 'ARRAY') {
        my @found;
        push @found, _scan_sops_display_forms($_, $metadata, $path) for @$node;
        return @found;
    }

    # Filter to UNENCRYPTED leaves: an encrypted slot holds an ENC[...] blob
    # whose plaintext the digest covers, never the wire text, so the detection
    # rule below cannot fire on an encrypted leaf's stringify.
    return () if $metadata->should_encrypt_path($path);
    return () if !defined $node || ref $node || blessed $node;
    my $text = "$node";

    return () unless _is_sops_display_form_text($text);
    return [ [@$path], $text ];
}

# The wire text sops's Go printer writes for a typed value when the store has
# no type label: dotenv and INI. Four families cover every Go print form
# measured against sops 3.13.3 (docs/adr/0052):
#
#   true        -- bool
#   false       -- bool
#   <nil>       -- null
#   N.0         -- a float whose textual rendering has a fractional zero
#   mE[+-]k     -- a float whose textual rendering is in exponent form
#                 (Go prints small exponents as decimal, so 1e2 -> 100.0,
#                 which the N.0 family catches; 1.5e-5 -> 1.5E-05)
sub _is_sops_display_form_text {
    my ($text) = @_;
    return 1 if $text eq 'true' || $text eq 'false';
    return 1 if $text eq '<nil>';
    return 1 if $text =~ /\A-?[0-9]+\.0\z/;
    return 1 if $text =~ /\A-?[0-9.]+E[+-][0-9]+\z/;
    return 0;
}

sub _mac_digest {
    my (%args) = @_;
    my $leaves   = $args{leaves};
    my $metadata = $args{metadata};
    my $data_key = $args{data_key};   # decrypt side only

    my $only_encrypted = $metadata && $metadata->mac_only_encrypted;

    my $ctx = Digest::SHA->new(512);
    $ctx->add($MAC_ONLY_ENCRYPTED_INIT) if $only_encrypted;

    for my $leaf (@$leaves) {
        my ($path, $value) = @$leaf;
        # Asked ONCE per leaf and handed on, because it now answers two
        # questions and they must not be able to disagree: which leaves
        # mac_only_encrypted covers, and whether this one is ciphertext at all
        # (docs/adr/0049).
        my $selected = !$metadata || $metadata->should_encrypt_path($path);
        next if $only_encrypted && !$selected;
        $ctx->add(_mac_bytes($value, $path, $data_key, $selected));
    }

    # Uppercase hex digest (SOPS format)
    return uc($ctx->hexdigest);
}

sub _mac_bytes {
    my ($value, $path, $data_key, $selected) = @_;

    $selected = 1 unless defined $selected;

    # Decrypt side. Hash the authenticated plaintext exactly as it came off
    # the cipher: running it back through decrypt_value's type conversion
    # would hash '007' as 7 and Go's 100000000000000000000 as 1e+20, and the
    # document would fail its own MAC. type:bool is the one case that needs
    # normalising, because SOPS's ToBytes titlecases the boolean it parsed
    # rather than echoing the spelling it was given.
    #
    # $selected is the encryption rule's answer for this path, and it is what
    # decides whether the leaf is ciphertext at all -- _decrypt_tree's rule,
    # asked here so the digest covers what the tree walk returned. Where the
    # rule EXCLUDES the leaf, its ENC[...] text is a literal and goes into the
    # digest as it stands. Read off sops's own `computed` figure on a MAC
    # mismatch: SHA-512 of the ENC[...] string, byte for byte, and repairing
    # the stored MAC to that digest makes `sops -d` exit 0. docs/adr/0049.
    if ($selected && defined $data_key
        && File::SOPS::Encrypted->is_encrypted($value)) {
        # A value that will not parse or will not decrypt used to be skipped
        # here, so the digest quietly covered a different document than the one
        # on disk and the only symptom was "MAC verification failed" with no
        # indication of which leaf caused it. That is what made every other MAC
        # defect in this distribution expensive to find. Fail at the leaf, and
        # say which leaf.
        my ($bytes, $type) = do {
            my @r = eval {
                my $enc = File::SOPS::Encrypted->parse($value);
                ($enc->decrypt_bytes(key => $data_key, aad => _path_to_aad($path)),
                 $enc->type);
            };
            croak _at_path($path, $@) if $@;
            @r;
        };
        return $bytes unless $type eq 'bool';
        return (lc($bytes) eq 'true' || $bytes eq '1') ? 'True' : 'False';
    }

    # Encrypt side, and unencrypted leaves on the decrypt side.
    return _value_to_bytes($value);
}

# Leaves in sorted-key order: [ [ \@path, $value ], ... ]
sub _sorted_leaves {
    no warnings 'recursion';
    my ($node, $path, $out, $depth) = @_;

    $depth = ($depth // 0) + 1;
    _assert_depth($depth) if ref $node eq 'HASH' || ref $node eq 'ARRAY';

    if (ref $node eq 'HASH') {
        for my $k (sort keys %$node) {
            push @$path, $k;
            _sorted_leaves($node->{$k}, $path, $out, $depth);
            pop @$path;
        }
    }
    elsif (ref $node eq 'ARRAY') {
        # SOPS does NOT add array index to path - all elements share parent's
        _sorted_leaves($_, $path, $out, $depth) for @$node;
    }
    else {
        # The COPY is taken here and only here: $path is one array walked down
        # and back up, so a leaf that kept the reference would end up holding
        # whatever the walk was looking at when it finished.
        push @$out, [ [@$path], $node ];
    }

    return $out;
}

# Leaves in document order. $ordered is the same document reparsed with key
# order preserved and supplies the order; $node is the tree the rest of the
# library is working with and supplies the values, so the digest never sees a
# value the second parser resolved differently.
#
# A structural disagreement between the two is REPORTED, at the path it happens
# at. It used to return the leaves collected so far, which is not "verification
# fails" but "verification is performed over part of the document" -- and since
# a missing key contributed an undef leaf, which hashes as nothing, that could
# still produce a matching digest. Even when it did fail, the only symptom was
# a bare "MAC verification failed" with no hint that half the tree had been
# dropped before the digest was taken.
sub _document_leaves {
    no warnings 'recursion';
    my ($ordered, $node, $path, $out, $depth) = @_;

    $depth = ($depth // 0) + 1;
    _assert_depth($depth) if ref $ordered eq 'HASH' || ref $ordered eq 'ARRAY';

    if (ref $ordered eq 'HASH') {
        croak _at_path($path, "the document has a mapping here but the parsed "
            . "tree does not, so the digest cannot be built over the same "
            . "values the file contains")
            unless ref $node eq 'HASH';

        for my $k (keys %$ordered) {
            croak _at_path([@$path, $k], "present in the document but not in "
                . "the parsed tree")
                unless exists $node->{$k};
            push @$path, $k;
            _document_leaves($ordered->{$k}, $node->{$k}, $path, $out, $depth);
            pop @$path;
        }
    }
    elsif (ref $ordered eq 'ARRAY') {
        croak _at_path($path, "the document has a sequence here but the parsed "
            . "tree does not")
            unless ref $node eq 'ARRAY';
        croak _at_path($path, sprintf("the document has %d entries here but "
            . "the parsed tree has %d", scalar @$ordered, scalar @$node))
            unless @$ordered == @$node;

        _document_leaves($ordered->[$_], $node->[$_], $path, $out, $depth)
            for 0 .. $#$ordered;
    }
    else {
        # Only a CONTAINER here is a disagreement. A blessed scalar is a leaf:
        # a JSON::PP::Boolean is what the format parsers hand back for a bare
        # true/false, while the order-preserving reparse yields a plain scalar
        # for the same node -- the two disagree about the boolean's
        # REPRESENTATION, never about the document's shape, and $ordered is
        # consulted for order only.
        croak _at_path($path, "the document has a scalar here but the parsed "
            . "tree has a " . lc(ref $node))
            if ref $node eq 'HASH' || ref $node eq 'ARRAY';

        # A copy, for the same reason _sorted_leaves takes one: $path is shared
        # and unwound.
        push @$out, [ [@$path], $node ];
    }

    return $out;
}

# The order-preserving reparse that supplies _document_leaves with the
# document's key order -- ASKED OF THE FORMAT HANDLER, not performed here.
#
# The mechanism is one thing, but it has two halves and only one of them is
# format-independent. Reading a document's key order out of raw text is
# entirely format knowledge: which reader can parse it, what "one document"
# means for it, and WHERE its metadata sits (a `sops` mapping in YAML and JSON,
# top-level `sops_*` keys in an env file, a `[sops]` section in an ini one).
# Walking that order against the real tree and hashing what it points at is
# not. So the handler answers the first question and this module owns the
# second. See docs/adr/0036, which refines docs/adr/0001 rather than replacing
# it: YAML::PP still supplies order and nothing else, and still supplies it for
# both formats -- it is now Format::YAML that says so.
#
# THE CONTRACT a handler's parse_in_document_order must meet, in full:
#
#   * Take the raw document text. Return a HashRef of the same SHAPE as the
#     handler's own parse() -- mappings where parse() has mappings, sequences
#     of the same length, leaves where parse() has leaves. The VALUES are never
#     read, only the shape, so a scalar the two readers resolve differently
#     cannot move a digest.
#   * Every mapping in it must iterate its KEYS in document order. Perl's plain
#     hash cannot do that, so a handler whose parser has no order-preserving
#     mode has to supply the ordering itself -- a tied hash is the whole of
#     what "order-preserving" means here.
#   * The metadata section must already be gone.
#   * Decline -- return nothing, or die -- when the text cannot be read that
#     way. Declining is safe; guessing is not.
#
# FAILING SAFE IS THE PROPERTY THAT MATTERS. Losing the order costs a fallback
# to sorted keys, which is the same order for every file this library writes
# and a failed verification for one it does not. Getting the order WRONG can
# only make verification fail too, never wrongly succeed -- the digest is over
# the same values either way. That is why every failure below returns undef
# instead of raising: a handler that cannot read its own document must not be
# able to turn a MAC check into an error the caller reads as corruption.
#
# The one thing that is NOT a document problem is a format class that cannot do
# this at all. That is a hole in this distribution, not in the file, and it
# would degrade every document in that format to sorted order silently -- which
# is precisely the failure k74 exists to prevent for env and ini. It is
# loud.
sub _parse_in_document_order {
    my ($content, $format_class) = @_;
    return unless defined $content;

    # The historical one-argument form: no format class means the YAML
    # handler, which is what read both formats before this split and still
    # reads both (see File::SOPS::Format::JSON::parse_in_document_order).
    $format_class ||= $FORMATS{yaml};

    croak "Format handler $format_class cannot recover document key order "
        . "(no parse_in_document_order method), so the MAC could only be "
        . "checked in sorted key order -- which is not the order a document "
        . "in this format is written in"
        unless $format_class->can('parse_in_document_order');

    my $ordered = eval { $format_class->parse_in_document_order($content) };

    # A single document is a HashRef, byte-identical to before. A multi-document
    # stream is an ArrayRef of ordered documents (docs/adr/0033, k31): the
    # handler reads the stream in list context, so document i's order pairs with
    # document i's values in _verify_mac. Either shape is validated here; a
    # handler that cannot read the text returns neither and falls back to
    # sorted order.
    if (ref $ordered eq 'ARRAY') {
        return unless @$ordered;
        for my $doc (@$ordered) {
            return unless ref $doc eq 'HASH';
        }
        return $ordered;
    }

    return unless ref $ordered eq 'HASH';
    return $ordered;
}

# edit on a multi-document YAML stream is refused -- not because the write
# cannot be done (it can, since k31 step 5), but because its semantics are
# undecided. edit re-encrypts under a NEW data key where sops edit keeps the
# existing one (k41), and docs/adr/0033 deliberately leaves edit-on-a-stream
# open under "What this does not decide". Enabling it here would settle k41
# by accident, so both edit paths -- a multi-document original, and a
# single-document file the editor turns into a stream -- refuse here. A
# single-document file (or a format with no document stream) has a list of one,
# or none, and passes straight through.
sub _refuse_edit_multidoc {
    my ($documents) = @_;

    return unless ref $documents eq 'ARRAY' && @$documents > 1;

    croak sprintf(
        "edit on a multi-document YAML stream (%d documents) is not supported: "
        . "edit re-encrypts under a NEW data key (unlike sops edit, k41), "
        . "and docs/adr/0033 deliberately leaves edit-on-a-stream semantics "
        . "open. Reading and writing streams both work -- use decrypt and "
        . "encrypt to change one, or resolve k41 first.",
        scalar @$documents
    );
}

# The MAC digest input for a value, which is by definition the same bytes the
# cipher gets. This used to be a second implementation of the type ladder and
# the value->bytes conversion, kept byte-identical to
# File::SOPS::Encrypted's by hand. It never was: when the two drifted the
# ciphertext and the digest were consistently wrong TOGETHER, so every
# self-produced file verified and only the Go binary disagreed. There is now
# one implementation, and this is a call to it.
sub _value_to_bytes {
    my ($value) = @_;
    return File::SOPS::Encrypted->value_to_bytes($value);
}

sub _extract_path {
    my ($data, $path, $doc_label) = @_;

    my @parts = _split_path($path);

    # $doc_label names which document is being searched, and appears in every
    # navigation failure only when a document axis is in play (a multi-document
    # stream, docs/adr/0033). For a single-document file it is undef and the
    # messages are byte-identical to before -- so a mistake in `document` reads
    # as one, not as a typo in `path`, without changing the single-document
    # wording every existing caller sees.
    my $in_doc = defined $doc_label ? " in $doc_label" : '';

    # Navigation failure is an error at EVERY depth. It used to be an error
    # only when nested: a missing top-level key fell through the loop and came
    # back as undef, indistinguishable from a key whose value really is null.
    # sops answers the same question the same way at every level --
    # `error truncating tree: component ['nope'] not found`, exit 1.
    my $current = $data;
    my @walked;
    for my $part (@parts) {
        my $where = @walked ? join(':', @walked) : '(document root)';

        if (ref $current eq 'HASH') {
            croak "Cannot navigate path '$path'$in_doc: component '$part' not "
                . "found under $where"
                unless exists $current->{$part};
            $current = $current->{$part};
        }
        elsif (ref $current eq 'ARRAY' && $part =~ /\A\d+\z/) {
            croak "Cannot navigate path '$path'$in_doc: index $part is out of "
                . "range at $where"
                unless $part <= $#$current;
            $current = $current->[$part];
        }
        else {
            croak "Cannot navigate path '$path'$in_doc: $where is not a "
                . (ref($current) eq 'ARRAY' ? "list index" : "collection")
                . ", so it has no component '$part'";
        }

        push @walked, $part;
    }

    return $current;
}

# ["database"]["password"], ['database'][0], or database.password / .items.0
#
# The bracket form used to be matched with /\["([^"]+)"\]/g, which only knows
# QUOTED keys -- so the documented ["items"][0] matched only the first
# component and extract handed back the whole arrayref instead of the element.
# An unquoted component is what an index looks like, and it is the form sops
# itself accepts: `sops -d --extract '["items"][0]'` returns the element.
sub _split_path {
    my ($path) = @_;

    unless ($path =~ /\A\[/) {
        $path =~ s/\A\.//;
        return split /\./, $path;
    }

    my @parts;
    my $rest = $path;
    while (length $rest) {
        $rest =~ s{\A \[ (?: "([^"]*)" | '([^']*)' | ([^\[\]]+) ) \] }{}x
            or croak "Cannot parse path '$path' at '$rest': expected "
                   . qq{["key"], ['key'] or [index]};
        push @parts, $1 // $2 // $3;
    }

    return @parts;
}

sub _detect_format {
    my ($content) = @_;

    # Try to detect based on content
    if ($content =~ /^\s*\{/) {
        return 'json';
    }
    # Asked of the handler rather than spelled here: what an env document looks
    # like includes where its metadata sits, and `sops_` has one spelling in
    # this distribution (File::SOPS::Metadata::Flat's prefix). This sub is only
    # ever asked about ENCRYPTED content, which is what makes the question
    # answerable at all -- a plaintext .env and a plaintext .properties file
    # are the same bytes.
    return 'env' if File::SOPS::Format::ENV->detect_content($content);
    # Asked AFTER env for the same reason env is asked after JSON: an ini
    # document is recognised by a `[sops]` section, and a dotenv document is
    # recognised by a `sops_` key, so neither can answer for the other -- but
    # any `key: value` line scans as an ini pair, so this is the widest
    # grammar of the three and goes last.
    return 'ini' if File::SOPS::Format::INI->detect_content($content);
    return 'yaml';
}

sub _detect_format_from_filename {
    my ($filename) = @_;

    return 'json' if $filename =~ /\.json$/i;
    return 'yaml' if $filename =~ /\.ya?ml$/i;
    return 'env'  if $filename =~ /\.env$/i;
    return 'ini'  if $filename =~ /\.ini$/i;
    return 'yaml';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS - Perl implementation of Mozilla SOPS encrypted file format

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use File::SOPS;

    # Encrypt a data structure
    my $encrypted = File::SOPS->encrypt(
        data       => {
            database => {
                password => 'secret123',
                host     => 'db.example.com',
            },
        },
        recipients => ['age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p'],
        format     => 'yaml',
    );

    # Decrypt
    my $data = File::SOPS->decrypt(
        encrypted  => $encrypted,
        identities => ['AGE-SECRET-KEY-1...'],
    );

    # File operations
    File::SOPS->encrypt_file(
        input      => 'secrets.yaml',
        output     => 'secrets.enc.yaml',
        recipients => ['age1...'],
    );

    File::SOPS->decrypt_file(
        input      => 'secrets.enc.yaml',
        output     => 'secrets.yaml',
        identities => ['AGE-SECRET-KEY-1...'],
    );

    # Encrypt a file over itself, atomically
    File::SOPS->encrypt_in_place(
        file       => 'secrets.yaml',
        recipients => ['age1...'],
    );

    # Decrypt, open $EDITOR, re-encrypt
    File::SOPS->edit(
        file       => 'secrets.enc.yaml',
        identities => ['AGE-SECRET-KEY-1...'],
    );

    # Extract single value
    my $password = File::SOPS->extract(
        file       => 'secrets.enc.yaml',
        path       => '["database"]["password"]',
        identities => ['AGE-SECRET-KEY-1...'],
    );

    # Rotate data key
    File::SOPS->rotate(
        file       => 'secrets.enc.yaml',
        identities => ['AGE-SECRET-KEY-1...'],
    );

    # Take the recipients and rules from the .sops.yaml governing a file
    my %args = File::SOPS->creation_rules_for(file => 'secrets/prod.yaml');
    File::SOPS->encrypt_in_place(file => 'secrets/prod.yaml', %args);

=head1 DESCRIPTION

File::SOPS is a pure Perl implementation of Mozilla SOPS (Secrets OPerationS),
compatible with the reference Go implementation at L<https://github.com/getsops/sops>.

SOPS encrypts B<values> in structured files (YAML, JSON) while keeping B<keys>
readable. This enables:

=over 4

=item * Git-friendly diffs - see which keys changed without decrypting

=item * Partial file inspection without full decryption

=item * Multiple encryption backends (currently age, with PGP/KMS planned)

=item * MAC verification to detect tampering

=back

=head2 How SOPS Works

=over 4

=item 1. Generate a random 256-bit data key

=item 2. Encrypt the data key for each recipient using age (X25519 + ChaCha20-Poly1305)

=item 3. Store encrypted data keys in the C<sops> metadata section

=item 4. Encrypt each value with AES-256-GCM using the data key

=item 5. Compute MAC over the entire structure for tamper detection

=back

=head2 Encrypted Value Format

Each encrypted value is stored as:

    ENC[AES256_GCM,data:base64==,iv:base64==,tag:base64==,type:str]

=head2 File Structure Example

    database:
        password: ENC[AES256_GCM,data:xyz,iv:abc,tag:def,type:str]
        host: ENC[AES256_GCM,data:xyz,iv:abc,tag:def,type:str]
    sops:
        age:
            - recipient: age1ql3z7hjy...
              enc: |
                -----BEGIN AGE ENCRYPTED FILE-----
                <encrypted data key>
                -----END AGE ENCRYPTED FILE-----
        lastmodified: "2025-01-10T12:00:00Z"
        mac: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
        version: 3.7.3

=head2 Special Features

=over 4

=item * B<Encryption rules> - C<unencrypted_suffix> (C<_unencrypted> by
default), C<encrypted_suffix>, C<unencrypted_regex> and C<encrypted_regex>
choose which values get encrypted; the rest stay readable but are still
covered by the MAC. See L</Choosing what gets encrypted>

=item * B<Key rotation> - Re-encrypt all values with a new data key via L</rotate>

=item * B<Multiple recipients> - Encrypt once, multiple recipients can decrypt

=back

=head2 Character encoding

B<The API boundary is characters. The wire is UTF-8 bytes. Encoding happens
exactly once, and this module owns it.>

Everything File::SOPS hands you and everything it takes from you is a Perl
B<character string>: the keys and values you pass to L</encrypt>, the tree
L</decrypt> returns, the value L</extract> returns, and the path you look it up
by. Encoding to UTF-8 happens at the edge where data becomes ciphertext, digest
input or file content -- never in your code:

=over 4

=item * Values, and the key path that forms each value's B<AAD>, are UTF-8
encoded on the way into AES-GCM, and the MAC digest is taken over those same
UTF-8 bytes. This is what the Go implementation authenticates against; a
document whose keys or values leave the ASCII range is not interoperable
otherwise.

=item * L</decrypt> reverses it, so a structure survives
C<encrypt>/C<decrypt> unchanged and C<is_deeply> against the original holds for
any input. Prior to 0.003 decrypted values came back as UTF-8 B<bytes>, which
compared unequal to the characters that went in and turned into mojibake when
L</decrypt_file> encoded them a second time.

=item * L</encrypt_file> and L</decrypt_file> read and write UTF-8 encoded
files. They decode on the way in and encode on the way out, so the characters
rule holds across the file API too.

=back

The one place bytes surface deliberately is C<type:bytes>, SOPS's binary type,
which is neither encoded on the way in nor decoded on the way out, because it
is not text. See L<File::SOPS::Encrypted/value_to_bytes>.

=head3 The boundary is characters, and it does not read Perl's UTF-8 flag

B<Do not hand C<encrypt> UTF-8 bytes.> Decode them first:

    utf8::decode($value);              # or read the file with an :encoding layer

Everything that crosses to the wire -- the value, and the key path that forms
its AAD -- is UTF-8 encoded B<unconditionally>. Perl's UTF-8 flag is not
consulted, because below U+0100 it is a storage detail and not a statement
about meaning: C<"caf\x{e9}"> may be held as one byte or as two, Perl considers
both the same string, and both serializers write it to the file as
C<caf\xc3\xa9> either way. A rule that read the flag would disagree with the
bytes our own emitter wrote, and a document that disagrees with itself fails
its own MAC.

Prior to 0.003 the value was encoded only when the flag was set, so an
unflagged C<"caf\x{e9}"> reached the wire as the single byte C<\xe9>. With
C<unencrypted_suffix> -- on by default -- such a document failed its own MAC
and C<sops -d> reported C<MAC mismatch>; when the value was encrypted the
document was self-consistent but C<sops -d> handed the value back as
C<!!binary Y2Fm6Q==> rather than as C<café>. Passing UTF-8 bytes appeared to
work in those releases, and for encrypted values it did; for unencrypted ones
the emitter double-encoded them and the document already failed verification.
See
L<docs/adr/0003|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0003-value-encoding-is-unconditional-like-the-aad.md>.

=head2 Value types

B<A value's C<type:> on the wire is decided by what the value is, never by
what its text looks like.> A Perl string encrypts as C<type:str> however
numeric or boolean it reads:

    File::SOPS->encrypt(data => { v => 'true' })  # type:str,   plaintext true
    File::SOPS->encrypt(data => { v => '007'  })  # type:str,   plaintext 007
    File::SOPS->encrypt(data => { v => '1.50' })  # type:str,   plaintext 1.50
    File::SOPS->encrypt(data => { v => 5432   })  # type:int,   plaintext 5432
    File::SOPS->encrypt(data => { v => 1.50   })  # type:float, plaintext 1.5
    File::SOPS->encrypt(data => { v => JSON->true })  # type:bool, plaintext True

The C<JSON-E<gt>true>/C<JSON-E<gt>false> in the last line is a class-method
call on the C<JSON> package -- it is not imported by C<use File::SOPS;>
(nothing is; namespace::clean strips it back out), and it works under a bare
C<use File::SOPS;> only by accident, because CryptX loads JSON.pm on the
way to L<Crypt::AuthEnc::GCM>. Rely on the accident and your code breaks
the moment a future CryptX stops loading JSON. The caller has to say so
explicitly: C<< use JSON::MaybeXS qw(JSON); >> -- JSON::MaybeXS is
already a prerequisite via the L<Format::JSON|File::SOPS::Format::JSON>
handler, so this is a use-line, not a new dependency.

This is the rule the reference implementation follows -- it types a value by
what the YAML/JSON parser returned, so a quoted scalar is a string -- and
L<YAML::XS> and L<Cpanel::JSON::XS> preserve the same distinction, so a
document loaded from a file keeps the types the file gave it. Perl has no native
boolean, so C<type:bool> requires C<JSON-E<gt>true>/C<JSON-E<gt>false> or a
C<true>/C<false> loaded from YAML or JSON.

Prior to 0.003 the type was guessed by pattern-matching the value's text. That
turned C<'true'> into a boolean and C<'007'> into the integer 7 on the way
back out, and -- because the reference implementation renormalises a numeric
plaintext when it recomputes the MAC, C<007> to C<7> and C<1.50> to C<1.5> --
made C<sops -d> reject any document containing such a value outright.

The full rule, the caller-visible round trips it changes, and the one case
where Perl's flags can be contaminated by the caller are in
L<File::SOPS::Encrypted/detect_type> and
L<File::SOPS::Encrypted/value_to_bytes>.

=head3 Integers are Go's int64, and Perl's are wider

Perl's integers reach C<2**64-1>; the SOPS C<int> type is Go's C<int64> and
stops at C<2**63-1>. L</encrypt> B<dies> rather than write an integer outside
that range, and L</decrypt> dies rather than read one, because there is no wire
form that preserves it: C<type:int> makes C<sops -d> stop with C<strconv.Atoi:
value out of range>, and C<type:float> -- what sops's own JSON store falls back
to -- silently drops digits. Pass such a value as a B<string>; that is
C<type:str>, written verbatim, and it survives both implementations intact.
See L<File::SOPS::Encrypted/assert_representable>.

That rule is about a scalar B<Perl holds as an integer>, which since 0.003 a
bare JSON number in C<2**63 .. 2**64-1> is not: the parser hands back the
C<float64> Go reads there, so those documents are written rather than refused.
A caller who does hold such an integer has the other answer available too --
C<unpack('d', pack('d', $v))> is what sops writes for the same digits, at the
cost of the ones the double cannot hold. See
L</A number past Go's int64 is a float>.

=head3 A number past Go's int64 is a float

B<There is no big integer in the SOPS data model.> Past C<int64> a number is a
C<float64> to Go: sops writes such a leaf as C<type:float>, in an encrypted
slot and an unencrypted one alike, and C<sops -e> on a plaintext
C<99999999999999999999> writes C<100000000000000000000> into the file itself.
Since 0.003 this library agrees in B<JSON> as it always did in YAML.

The boundary is B<Go's>, not Perl's, and that is the whole rule. Perl's
integers are a magnitude wider, so two windows sit above C<2**63-1>; they reach
the tree as different scalars, and until 0.003 each of them got its own wrong
answer here:

    a bare JSON literal in    the decoder returns   until 0.003   since 0.003
    2**63 .. 2**64-1          a Perl integer        a croak       a float
    past 2**64-1              a plain string        a str         a float

The windows are positive-only. A Perl integer cannot reach below C<int64>'s
floor, so C<-9223372036854775808> is still an C<int>, and
C<-9223372036854775809> is already a plain string and already the upper
window's leaf.

The B<lower> window is the one where Perl can hold the integer and Go cannot.
L<Cpanel::JSON::XS> decodes C<9223372036854775808> into a Perl integer, so it
was an C<int> here and the C<int64> refusal above applied to it -- while sops
writes that same literal as a C<type:float> and normalises it to
C<9223372036854776000>, which is itself inside the window. L</rotate> therefore
refused a JSON document C<sops -e> had written and C<sops -d> reads, and
L</encrypt> refused the plaintext it was written from. Measured against sops
3.13.3: rotating such a document now writes the unencrypted slot back with the
digits it came with and C<sops -d> reads the result, and encrypting the
plaintext writes what C<sops -e> writes for the identical input. See k101
and
L<docs/adr/0021|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0021-a-json-number-go-cannot-hold-is-a-float-not-a-refusal.md>.

The B<upper> window is the one where the decoder cannot hold the digits at all
and hands them back as a plain B<string>, indistinguishable from the same
digits quoted, so C<100000000000000000000> was typed C<str> and L</rotate>
rewrote a document sops had written with a number there as a JSON B<string>.
See k63 and
L<docs/adr/0020|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0020-a-json-number-perl-cannot-hold-is-a-float-not-a-string.md>.

Both windows now hand back the leaf L<YAML::XS> has always returned for those
digits -- the double, carrying its source spelling -- so the value gets the
B<float> rules and neither the integer nor the string ones. A B<quoted>
C<"9223372036854775808"> is unaffected in either window and stays a C<str>, and
so is every value in a document this library wrote before 0.003: it carries an
upper-window number quoted, and it could not carry a lower-window one at all.

L</decrypt> hands such a leaf back as a B<number>. In an B<unencrypted> slot it
is a L<Scalar::Util/dualvar> and prints as the digits the document holds; in an
B<encrypted> one it is the bare NV every decrypted float is, so C<"$value">
goes through Perl's 15 significant digits and gives C<1e+20> where the upper
window's old string gave C<100000000000000000000>. L</extract> is the method
that prints all of them in either slot -- see the dualvar note there and
L<File::SOPS::Encrypted/canonical_float_dualvar>. L</decrypt_file> writes the
leaf into the plaintext as a bare number.

B<For the lower window what moved is the numeric half and not the printed one>,
and it is the only window where that can happen -- it is the only one Perl held
exactly. Measured per slot, on a document C<sops -e> wrote:

    decrypt / extract, encrypted slot     unchanged. sops already wrote
                                          type:float there, so this library
                                          has always read a float back
    decrypt / extract, unencrypted slot   prints the same digits as before,
                                          but 0 + $value is now the double
                                          those digits name where it used to
                                          be the digits themselves
    decrypt_file                          unchanged, byte for byte

C<0 + $value> for C<9223372036854776000> is C<9223372036854775808>, 192 short
of what the same scalar prints. That is not a number this library chose: it is
the C<float64> Go has been reading out of that leaf since sops wrote it, and
digesting for the MAC.

What B<is> lost is a digit the double never held. C<value_to_bytes> re-derives
the text from the number, so a hand-written literal that is not its double's
canonical decimal is written -- and read back -- rounded:
C<12345678901234567890> becomes C<12345678901234567000> and
C<99999999999999999999> becomes C<100000000000000000000>, which is what
C<sops -e> does to the same document.

The same re-derivation settles a B<verification> difference that used to go the
other way. A document whose unencrypted number is spelled differently from its
double's canonical decimal -- C<9223372036854776832>, whose double is the same
C<9223372036854775808> -- is one C<sops -d> accepts, because Go digests the
number and not the text. Until 0.003 this library digested the integer's own
digits and reported C<MAC verification failed> on such a file; it now digests
what Go digests, reads it, and L</decrypt_file> writes it out with the same
normalisation C<sops -d> writes. Measured against sops 3.13.3 on both sides.

Three things around these windows are still B<refused> rather than written --
the magnitude above them where a real non-finite double reaches an unencrypted
slot or states its own text, one whole format, and one kind of caller -- and a
caller meeting a wide number should know where all three are.

A literal that overflows a double -- C<1> followed by 400 zeros -- B<dies> in
L<File::SOPS::Encrypted/assert_representable>'s non-finite guard wherever it
reaches the tree as a real non-finite double, on every path that B<writes> the
value: L</encrypt>, L</encrypt_file>, L</encrypt_in_place>, L</rotate> and
L</edit>. That is any B<JSON> document, where L<Cpanel::JSON::XS> returns
C<+Inf> carrying the literal's own digits as its string half -- and it is that
B<stated text> the guard refuses, in either slot, because an encrypted slot is
derived from the number and would drop it without a trace. In JSON it is not an
extra restriction of ours -- sops refuses the same document itself and never
reaches a type: C<sops -e> stops at
C<Error unmarshalling file: [...] strconv.ParseFloat: value out of range>, exit
2, in an encrypted and an unencrypted slot alike, and C<sops -d> stops with the
same message, exit 1, on a document hand-edited to carry one. Measured against
sops 3.13.3.

A caller's own bare C<9**9**9> states nothing, and it is refused in an
B<unencrypted> slot only. In an B<encrypted> one it is now written, as
C<type:float> and the plaintext C<+Inf>, which is what C<sops -e> stores for
the same value in both formats. See
L<File::SOPS::Encrypted/assert_representable>, k122 and
L<docs/adr/0040|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0040-an-encrypted-slot-carries-a-non-finite-float-because-sops-writes-one.md>.

B<In YAML that literal is not refused any more, because it is not a number
there.> Since 0.003 L<File::SOPS::Format::YAML/parse> hands back the string
go-yaml reads -- C<1e400>, a 401-digit integer and the bare spellings C<Inf>,
C<NaN> and their relatives -- so the guard never sees a float, and the leaf is
written as C<type:str>, which is what C<sops -e> writes for the identical
plaintext (exit 0, measured against sops 3.13.3, encrypted and unencrypted slot
alike). Until 0.003 the same document could be neither written here -- all 20
measured hit the guard -- nor read, 17 of those 20 failing with C<MAC
verification failed>.

The B<read> paths follow from that and differ by format. In YAML L</decrypt>
and L</extract> hand the leaf back as a plain string carrying the literal's own
text, and the document verifies; L</A YAML literal that overflows a double
comes back as a string> under L</decrypt> has what that changed for a caller.
In JSON no such document verifies in either implementation: L</decrypt> stops
at C<MAC verification failed>, and with C<ignore_mac> the value is C<Inf> with
its digits gone.

The lower window in a B<YAML> document is refused, and sops cannot write one
either. L<YAML::XS> hands those digits back as a Perl integer, so the C<int64>
refusal above applies and L</encrypt> dies with that message; C<sops -e> on the
same plaintext stops at C<Error walking tree: Cannot walk value, unknown type:
uint64>, exit 23, in both slots, measured against sops 3.13.3. The upper window
in YAML has always been a float and is unaffected. Only JSON has a window Go
reads as a number and Perl reads as an integer.

A lower-window value that did B<not> come from a JSON parse -- a Perl integer
literal, a computed one, or one that came out of a YAML document -- is still
refused by L<File::SOPS::Encrypted/assert_representable>. The scalar the caller
handed over is an exact integer and no reader has spoken for it, so turning it
into a lossy double would be this library guessing. Say which one you mean:
C<unpack('d', pack('d', $v))> makes it the float sops writes, and C<"$v"> makes
it a C<type:str> that stores the digits exactly. That refusal is wider than it
strictly has to be -- of 35 literals measured across the window, 14 would have
produced a document C<sops -d> accepts in an unencrypted JSON slot -- and
narrowing it is open as k104.

=head3 Saying what a value is

There is no per-leaf type argument to L</encrypt>, and none is needed: the
scalar is the type, so you say what a value is by handing over the scalar that
says it.

    use JSON::MaybeXS qw(JSON);          # JSON->true is not exported by File::SOPS
    $data->{port}  = "$data->{port}";   # type:str
    $data->{port}  = 0 + $data->{port}; # type:int
    $data->{ratio} = unpack('d', pack('d', $data->{ratio}));  # type:float
    $data->{flag}  = JSON->true;        # type:bool
    $data->{admin} = ($level > 3);      # type:bool too, on perl 5.36+

The last line works because Perl marks its own booleans on the scalar since
5.36 -- C<!!1>, C<!!0> and every comparison's result -- and both emitters write
such an SV as a bare C<true>/C<false>. Until 0.003 it was C<type:int>, and the
resulting file failed its own MAC. See
L<File::SOPS::Encrypted/detect_type> and k90.

The C<ratio> line goes through C<pack>/C<unpack> rather than the more obvious
C<+ 0.0> because addition sets Perl's public C<SVf_IOK> on an B<integral>
result, and that flag is what decides the type: measured, C<0.0 + 2> is
C<type:int>, and so is C<0.0 + '2'>. C<pack('d', ...)> lays the value out as a
native double and C<unpack> builds a fresh scalar from those bytes, which is a
float and nothing else -- the same conversion
L<File::SOPS::Encrypted/decrypt_value> makes for the same reason. A literal
C<2.0> written in your own source is already a float and needs none of this.

The case that makes this worth spelling out is the one
L<File::SOPS::Encrypted/detect_type> warns about. Perl marks a string as
numeric B<in place> the first time it is read in numeric context, so

    if ($cfg->{port} > 1024) { ... }    # $cfg->{port} is now an int

turns a later C<< encrypt(data => $cfg) >> into C<type:int>. Reading a scalar
numerically sets the numeric flag but B<leaves the string alone>, so
C<< $cfg->{port} = "$cfg->{port}" >> puts it back exactly -- type C<str> and
the original text, padding and trailing zeros included.

What that idiom cannot undo is a numeric B<assignment>:

    $cfg->{ratio} += 0;                 # '1.50' is now the number 1.5
    $cfg->{ratio} = "$cfg->{ratio}";    # type:str, but the text is '1.5'

Here the scalar's string really was replaced, by your code, before this module
saw it. No argument to C<encrypt> could recover C<1.50> either -- a type
override would write the same C<1.5> under a different label -- so the value
has to be re-read from wherever it came from.

=head2 Multi-document YAML

B<Not supported, and refused rather than truncated.> A YAML file holding more
than one document (separated by C<--->) makes L</encrypt_file>, L</decrypt>,
L</extract> and L</rotate> die.

Until 0.003 such a file was accepted and silently reduced to its B<last>
document, so encrypting a two-document file wrote one document back and
discarded the other without an error. sops does support multi-document YAML;
what its model is, and why matching it is more than a parser change, is in
L<File::SOPS::Format::YAML/Multi-document YAML>.

=head2 How a file is written

B<Every method here that writes a file writes it atomically.> The document goes
to a temporary file in the same directory, which is then C<rename>d over the
target. Nothing ever observes a half-written document, and a failure anywhere
before the rename -- a full disk, a signal, an error from the cipher -- leaves
the file that was there exactly as it was. This holds for L</encrypt_file>,
L</decrypt_file>, L</encrypt_in_place>, L</edit> and L</rotate> alike, whether
the target already exists or not.

Until 0.003 only C<encrypt_in_place> and C<edit> did that. The other three
opened the target with C<< '>' >>, which truncates it before the first byte is
written, and then checked neither the C<print> nor the C<close> -- so a write
that ran out of disk left an empty file B<and reported success>. C<encrypt_file>
defaults C<output> to C<input> and C<rotate> always writes back over the file it
read, so in both cases the file that was destroyed was the only copy: for
C<rotate>, one whose data key had already been replaced.

=head3 What C<rename> costs

sops truncates the file and rewrites it in place. Keeping the inode is the one
thing that buys, and it costs the file if the write stops half way; on a secrets
file being replaced by a re-encryption of itself, that trade goes the other way
round. The differences that follow from it are all visible from outside:

=over 4

=item * The file gets a B<new inode>. B<Hard links to it keep the old content>
-- where sops, which rewrites the same inode, updates every link at once. A
file with C<n> links comes back with one link and the other C<n-1> still
pointing at the previous content.

=item * Replacing a file needs write permission on its B<directory>, not on the
file. A read-only file in a writable directory is refused with C<Could not
open in-place file for writing: ...: permission denied>, the same wording
C<sops -e -i> uses (measured, 3.13.3). C<chmod 0444> is a guard against these
methods. The directory, by contrast, must be writable -- a read-only
C<secrets/> is the precondition that lets C<chmod 0444> on the file mean
anything, and these methods cannot write into a directory that is not.

=item * A B<symlink> is resolved: the link is left alone and the file it points
at is replaced. sops does the same (measured, 3.13.3) -- what differs is only
that the target picks up a new inode.

=item * An existing file keeps its B<mode>; a file that has to be created gets
the mode C<< open '>' >> would have given it, C<0666> against the process
umask. That is what sops's C<--output> does as well, so a decrypted file this
writes is no more and no less protected than before -- if that is too open for
plaintext, set the umask or the mode yourself.

The match-sops decision is deliberate (k45): the alternative, a hard
C<0600> on every new output, would break a caller whose next step is
another process reading the file -- loudly, not silently -- and would
diverge from the reference implementation without a measurable security
gain over a umask set to 077 by the caller. L</edit> uses 0600 for its
own temporary copy, which is a different question -- that file is known
to be removed at the end of the call rather than passed on.

=back

A target that exists and is B<not a regular file> -- C</dev/stdout>,
C</dev/null>, a fifo -- is written through directly instead. There is nothing
there to protect, and renaming over it would replace the device itself with an
ordinary file. C<sops --output /dev/stdout> works, and so does passing that as
C<output> here.

=head3 Every YAML file starts with C<--->, where sops writes none

L<YAML::XS>'s emitter always writes the document-start marker, so line 1 of
B<every> YAML file this distribution produces is C<--->: the encrypted document
from L</encrypt>, L</encrypt_file>, L</encrypt_in_place>, L</rotate> and
L</edit>, and the plaintext from L</decrypt_file> and the copy L</edit> hands
the editor. sops writes neither (measured, 3.13.3):

    our encrypt_file    ->  "---\nhalf: ENC[...]"
    sops -e             ->  "whole: ENC[...]"
    our decrypt_file    ->  "---\nhalf: 1.5"
    sops -d             ->  "whole: 2"

It is cosmetic and not a compatibility difference. YAML resolves a document
with the marker and one without it identically, C<sops -d> accepts our files
(exit 0, pinned by C<t/04-interop.t>), and the MAC covers the B<values>, never
the serialized text -- so nothing about the digest, the ciphertext or the
metadata depends on that line. JSON has no such marker and is unaffected.

Where it is visible: a caller who diffs this output against C<sops -d>'s meets
one extra line at the top, and so does anything reading the file with something
stricter than a YAML parser.

It is documented rather than removed. Dropping it means changing what the
emitter emits, and the MAC's encrypt side rides on that same emitter (see
C<docs/adr/0001>), so it is a wire-format change for a cosmetic gain. k83.

=head2 encrypt

    my $encrypted = File::SOPS->encrypt(
        data               => \%data,
        recipients         => \@age_public_keys,
        format             => 'yaml',  # json / env / ini, defaults to 'yaml'
        mac_only_encrypted => 0,       # optional

        # optional, at most ONE of these four
        unencrypted_suffix => '_unencrypted',
        encrypted_suffix   => '_enc',
        unencrypted_regex  => '^public_',
        encrypted_regex    => '^secret_',

        # optional, carry another document's rules forward
        metadata           => $metadata,
    );

Encrypts a data structure for specified recipients.

Takes a HashRef in C<data>, encrypts all values (not keys) using AES-256-GCM,
and encrypts the data key for each age recipient. Returns serialized encrypted
content as a string.

C<data> may also be an B<ArrayRef of HashRefs>, one per document, to write a
multi-document YAML stream -- the inverse of what L</decrypt> returns for one
(see L<decrypt|/A multi-document YAML stream is an ArrayRef>). This is purely
additive: until 0.003 an ArrayRef raised C<data must be a hash ref>. Every
document is encrypted under the B<one> data key and carries the B<same> C<sops>
metadata block, byte-identical, and the documents are joined with C<--->. A
one-element ArrayRef writes a one-document file, byte-identical to the same bare
HashRef.

B<Only YAML has a document stream.> An ArrayRef of more than one document with a
C<format> of C<json>, C<env> or C<ini> is B<refused>, naming the document count
and the target -- that format cannot hold a stream, and writing one would drop
all but the first document, which is the C<sops> behaviour this library declines
to copy (docs/adr/0033 Decision 3).

Keys and values are character strings and are UTF-8 encoded on their way to the
cipher and the digest; the returned document is UTF-8 encoded bytes, ready to
write to a C<:raw> handle. See L</Character encoding>.

The C<recipients> parameter must be an ArrayRef of age public keys (starting
with C<age1...>).

B<Dies if C<data> has a top-level C<sops> key, in YAML or JSON.> That name is
where those formats put the metadata section, so a caller-supplied value at
that key would be overwritten -- after the digest had already covered it,
which leaves a document that fails its own MAC on the next read. Until 0.003
the user's value was silently replaced by the metadata, for every format,
and the resulting document failed its own MAC; for ENV and INI the
overwrite did not happen (the metadata lives in flat C<sops_> keys and in a
C<[sops]> section respectively), so C<sops> is a legitimate data key there.
sops refuses such a file too, with exit code 203, and its advice applies
here: rename the entry.

Supported formats: C<yaml>, C<yml>, C<json>, C<env>, C<ini>. C<dotenv> is
accepted as an alias for C<env>, which is the name sops itself uses for the
format.

The C<env> and C<ini> formats are B<untyped>, and that is visible to a caller:
an B<unencrypted> leaf comes back from the round trip as the text it was
written as -- C<42> as C<"42">, a boolean as C<"True">, an C<undef> as C<''>.
An encrypted leaf keeps its type, because the C<type:> label carries it.

C<env> is B<flat>: a nested value is refused, as sops refuses it, and a
comment lives under the document's empty key as a list. See
L<File::SOPS::Format::ENV>.

C<ini> is exactly B<two levels deep> -- section, then key. A value written
outside any section is in the section C<DEFAULT>, as it is for sops; a deeper
tree is refused (sops writes a dump of the Go value instead); and a section's
comments live under B<that section's> empty key, as a list, because that is the
path sops authenticates them under. See L<File::SOPS::Format::INI>.

A C<File::SOPS::Comment> in C<data> is written as a sops comment
(C<type:comment>) and is left out of the MAC, which is what sops does with one.
It has to sit in a B<list>, and in a slot the encryption rules encrypt: those
are the only places a SOPS document holds a comment as a leaf, and anywhere else
it is refused, naming the path. See L</A comment in a list comes back as a
File::SOPS::Comment>.

C<mac_only_encrypted> is the equivalent of the reference implementation's
C<--mac-only-encrypted>: it restricts the MAC to the values that are actually
encrypted, and records that choice in the C<sops> section so a reader knows
which rule to verify under. See
L<File::SOPS::Metadata/mac_only_encrypted>. Off by default, which is what sops
defaults to as well.

Turning it on has a consequence in YAML that is easy to miss, so it is warned
about rather than left to be discovered: an B<unencrypted> leaf is then covered
by no MAC at all, and this distribution and sops do not read every YAML spelling
the same way. C<mode_unencrypted: 0755> is the integer B<493> to sops and 755
here, and with C<mac_only_encrypted> set nothing fails -- C<sops -d> exits 0 and
hands back a different number. Encrypting such a document C<carp>s once per
such leaf, naming its key path and never its value; without the option the same
leaf is refused outright, since the document would fail its own MAC. See
L<File::SOPS::Format::YAML/serialize>.

One YAML divergence is warned about B<whatever> C<mac_only_encrypted> is set
to, because the MAC cannot catch it either way: a C<True> or C<False> B<string>
in an unencrypted slot is written as a bare C<True>, which Go's yaml.v3 resolves
as a B<boolean> while this module keeps a string. Both sides digest the same
bytes, so the MAC holds and C<sops -d> exits 0 -- but sops hands the value on as
a boolean, and any sops write-back (C<rotate>, C<set>, C<edit>) rewrites the
leaf to a bare C<true>, after which this module reads a boolean too. Encrypting
the leaf or using the JSON format avoids it; both are measured. See
L<File::SOPS::Format::YAML/serialize>.

=head3 Choosing what gets encrypted

C<unencrypted_suffix>, C<encrypted_suffix>, C<unencrypted_regex> and
C<encrypted_regex> are the equivalents of the sops command line options of the
same names, and B<at most one of them may be given> -- passing two dies, as
does a document carrying two, because sops refuses such a file outright. Each
is matched against B<every component> of a value's key path, so
C<< encrypted_suffix => '_enc' >> encrypts everything under a C<database_enc:>
block as well as a C<password_enc:> anywhere in the document; the exact rule
is in L<File::SOPS::Metadata/should_encrypt_path>.

With none of them given, C<unencrypted_suffix> defaults to C<_unencrypted>,
which is what sops does when it creates a document. Pass
C<< unencrypted_suffix => undef >> for a document with B<no> rule, where every
value is encrypted whatever its key.

Values excluded from encryption are still covered by the MAC, so they are
authenticated even though they are readable -- unless C<mac_only_encrypted> is
on.

The same rule is applied on the way B<out>, and it is what decides what a leaf
B<is>: see L</The rule decides what a value is, in both directions>.

=head3 Reusing another document's rules

C<metadata> takes a L<File::SOPS::Metadata> object -- typically one just
parsed out of an existing file -- and starts from its encryption policy
instead of from the defaults. Only the policy is taken: the rules and
C<mac_only_encrypted>. The key material, the MAC and C<lastmodified> are
always regenerated, because a new data key is generated here and none of them
would survive it. See L<File::SOPS::Metadata/policy_args>.

Any rule passed explicitly alongside C<metadata> replaces the template's rule
rather than adding to it. This is how L</rotate> keeps a file's rules across a
key rotation.

Dies if C<metadata> carries a rule this distribution cannot apply
(C<unencrypted_comment_regex> or C<encrypted_comment_regex>, which select
values by their comment -- neither parser here keeps comments, so every value
would be classified wrongly).

=head3 A structure that contains itself is refused

B<New in 0.003.> C<data> must be a finite tree. A value that contains itself --
a hash or array reachable from inside its own value -- is refused, naming the
path at which the cycle closes:

    my $h = { a => 1 };
    $h->{self} = $h;
    File::SOPS->encrypt(data => $h, recipients => \@r);
    # dies: self: this value contains itself, so the document has no finite
    #       set of values to encrypt or to hash. ...

B<This used to hang.> Not die, not return a truncated document: the process did
not come back, and no C<eval> could catch it. There are two roads to it and both
are now refused at the same guard. The one above is a caller's own structure.
The other is a document: L<YAML::XS> resolves a B<recursive anchor> into a real
Perl cycle and hands it over, so

    root: &a
      b: *a

hung L</encrypt_file> and L</encrypt_in_place> as well, and its encrypted
counterpart hung L</decrypt>, L</decrypt_file>, L</extract>, L</rotate> and
L</edit>. All eight now die instead.

Refusing is what the reference implementation does. Measured against sops
3.13.3, the document above is rejected in both directions --
C<Error unmarshalling file: yaml: anchor 'a' value contains itself> (exit 2)
from C<sops -e>, and C<yaml: anchor 'a' value contains itself> (exit 1) from
C<sops -d>. There is also nothing else this could honestly do: such a document
has no finite set of values, so it has no digest and no serialization, and
terminating the walk early would have written a file whose contents and whose
MAC describe a tree that is not the one it was given.

B<An anchor that is merely reused is not affected> and never was. Sharing a
subtree is ordinary YAML, sops accepts it and expands it -- C<base: &b> with
C<other: *b> encrypts to two independent C<ENC[...]> values -- and so does this.
Only a container that is its own ancestor is refused.

A document that is acyclic but shares its aliases exponentially is a separate
exposure with a separate guard, described under
L</A document that expands far beyond what it contains is refused>.

See k110 and
L<docs/adr/0025|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0025-a-document-that-contains-itself-is-refused-not-walked.md>.

=head3 A document that expands far beyond what it contains is refused

B<New in 0.003.> Sharing an anchor is ordinary YAML and is expanded, here and
by sops alike. Sharing it B<exponentially> is not: aliases that are perfectly
acyclic still double the document at every level, so

    l0: &l0
      v: 1
    l1: &l1
      a: *l0
      b: *l0
    ... 25 levels

is 727 bytes that expand to a tree with C<2**25> leaves. B<This used to hang>,
in the same eight entry points and for the same practical reason as
L</A structure that contains itself is refused> -- and it is not caught by that
guard, because the document really is acyclic. Measured before the guard:
9 levels encrypted in 0.06s, 12 in 0.5s, 15 in 4.3s, and 25 never came back.

Such a document is now refused, naming how far out of proportion it is:

    # dies: this document expands to 8146 values from the 60 it holds, which
    #       is the alias bomb sops refuses: "yaml: document contains
    #       excessive aliasing". ...

The threshold is B<not> this library's. It is go-yaml's, reproduced on
go-yaml's own counters, because an independently chosen one would refuse
documents sops accepts. What it budgets is a B<ratio> -- roughly how far the
expanded document exceeds the document as written, up to about 100 times,
tightening to about 1.1 times as the expansion approaches four million values
-- and B<not> a size. sops accepts a 206,104-value expansion and refuses an
8,146-value one, and so does this. Bisected against sops 3.13.3 in four
differently shaped families, the accept/refuse boundary is the same document
on both sides.

There is no size at which a document is refused for being large: one that
shares nothing amplifies nothing and is accepted however big it gets.

A caller's own structure reaches the same guard by the other road. One hash
reference held in many places is the same blowup with no YAML involved, and
C<format =E<gt> 'json'> is exposed to it exactly as YAML is.

Refusing is what the reference implementation does, in both directions --
C<Error unmarshalling file: yaml: document contains excessive aliasing>
(exit 2) from C<sops -e>, and C<yaml: document contains excessive aliasing>
(exit 1) from C<sops -d>.

See k112 and
L<docs/adr/0027|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0027-the-alias-budget-is-a-ratio-and-it-is-go-yamls-ratio.md>.

=head3 A document nested deeper than sops can carry is refused

B<New in 0.003.> A document is walked at most C<$File::SOPS::MAX_DEPTH>
containers deep, 10000 by default, and one nested deeper is refused rather than
walked:

    # dies: this document nests containers more than 10000 deep, which is as
    #       deep as this library walks. sops stops as well: ...

The number is sops's, not this library's. Measured against sops 3.13.3,
counting containers from the document's own root mapping: go-yaml accepts
10001 and refuses 10002 with C<yaml: exceeded max depth of 10000>, in both
directions and B<ahead> of the data key; Go's JSON encoder accepts 10000 and
refuses 10001 with C<exceeded max depth>. 10000 is therefore the deepest a
document can be and still be readable in both formats. It is one level tighter
than go-yaml alone would be, deliberately: the alternative is writing a JSON
file sops cannot read back.

Nothing that came from a sops-written document can reach this. It exists for
what a caller can build in Perl and for what a hand-written file can carry, and
because a walk that cannot say no has only a hang to offer -- before this,
4000 levels took 101s and 410 MB in the MAC's walk alone.

C<$File::SOPS::MAX_DEPTH> is writable and is what a caller processing
untrusted documents can lower to refuse deep documents earlier. Raising it
above 10000 produces documents sops will refuse to read.

See k117.

=head3 A plain YAML infinity is the float go-yaml reads

B<New in 0.003, and a change for existing callers of every method that reads a
YAML file.> A leaf a YAML document wrote as a B<plain> scalar whose token
go-yaml resolves to a non-finite float -- C<.inf>, C<.Inf>, C<.INF>, the same
three with a leading C<+> or C<->, C<.nan>, C<.NaN>, C<.NAN> -- is that float
here too, carrying the document's own token as its text. A B<quoted> C<".inf">
is the string it has always been; the difference is decided by asking
L<YAML::PP> how the document wrote the scalar, never by matching the leaf's
text. See L<File::SOPS::Format::YAML/A plain infinity comes back as the float
go-yaml reads>.

B<This applies to a plaintext file as well as to an encrypted one>, which is
what changed last: until then the repair ran only for a document that carried a
C<sops:> section, so this library's own L</decrypt_file> wrote
C<v_unencrypted: .inf> and its own L</encrypt_file> refused to read that file
back, and L</edit> could not save a document it had just opened. sops makes one
parse and this now makes one too.

What it means per slot, measured against sops 3.13.3 for all twelve spellings:

=over 4

=item * In an B<unencrypted> slot the leaf is written as the token the document
had, and the MAC digest covers C<+Inf> / C<-Inf> / C<NaN>. C<sops -d> reads it,
and for the three spellings C<sops -e> itself writes the wire bytes are
identical to sops's.

=item * In an B<encrypted> slot the leaf is B<refused>, naming the key path:
the wire form there is C<type:float> with the plaintext C<+Inf>, and
L<File::SOPS::Encrypted/encrypt_value> cannot see which format it is writing
for -- YAML would carry it, JSON cannot (C<sops -e> exit 4,
C<Error marshaling to json>). Before this such a leaf was written as a
C<type:str> holding C<.inf>, where C<sops -e> on the same plaintext writes a
C<type:float>: a working file that had silently stopped being a number. This is
a refusal where sops succeeds, and it is deliberate -- see k122, which is
where the encrypted slot gets the format it needs.

=item * In B<JSON> nothing changes at either end. C<.inf> is not JSON, so the
token cannot reach a JSON document to begin with.

=back

See k123 and
L<docs/adr/0034|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0034-a-plain-scalar-is-resolved-the-same-way-on-every-parse.md>.

=head2 decrypt

    my $data = File::SOPS->decrypt(
        encrypted   => $encrypted_content,
        identities  => \@age_secret_keys,
        format      => 'yaml',  # optional, auto-detected
        ignore_mac  => 0,       # optional, see below
        max_stanzas => 64,      # optional, see below
    );

Decrypts SOPS-encrypted content.

Takes encrypted content as a string, decrypts the data key using provided age
identities, verifies the MAC, and returns the decrypted data structure -- a
HashRef for a single-document file, or an B<ArrayRef of HashRefs> for a
multi-document YAML stream (see L</A multi-document YAML stream is an ArrayRef>).

The returned structure holds B<character strings>, so it compares equal to the
structure L</encrypt> was given. Do not decode it again. See
L</Character encoding>.

=head3 A multi-document YAML stream is an ArrayRef

B<New in 0.003.> A YAML file holding more than one document -- documents joined
by C<--->, as sops writes them -- is one tree with N branches carrying B<one>
C<sops> metadata section and B<one> MAC spanning every document in order. This
method reads such a stream and returns an ArrayRef whose elements are the
decrypted documents in document order; a file holding a single document still
returns a bare HashRef. Which shape you get mirrors the B<document>, not the
call, so code that wants to be shape-agnostic writes

    my @docs = ref $result eq 'ARRAY' ? @$result : ($result);

The metadata is taken from the B<first> document, exactly as sops does. A stream
carrying a C<sops> section only in a I<later> document surfaces no metadata and
is refused with C<No SOPS metadata found> -- the same C<sops metadata not found>
sops reports for it.

B<The MAC authenticates the concatenated leaf sequence across all documents, not
where the document boundaries fall.> Because the AAD carries no document index,
a value can be moved from one document to another undetected as long as the
concatenated leaf order is preserved; what the MAC does catch is a deleted,
duplicated, reordered or altered value. This is a property of the sops format,
not of this implementation. See L<File::SOPS::Format::YAML>.

Until 0.003 a multi-document stream was refused outright -- it was
L<File::SOPS::Format::YAML/parse> that stopped it, before C<decrypt> saw it -- so
no caller has ever received a value from this path, and widening the return type
over it breaks nothing.

B<New in 0.003, and a change for existing callers:> a JSON number past Go's
C<int64> comes back as a B<float>. Past C<2**64-1> it used to come back as a
string, so C<"$value"> can print C<1e+20> where it printed
C<100000000000000000000>; between C<2**63> and C<2**64-1> it used to come back
as an exact Perl integer, and there the printed digits are unchanged while
C<0 + $value> is now the double they name. Only a B<bare> literal is affected
-- a quoted C<"100000000000000000000"> is a string as it always was, and so is
every value in a document this library wrote before 0.003. Which slot moves
which half, and what is refused instead, are in
L</A number past Go's int64 is a float>. Unlike L</extract>, this
method does not wrap a float leaf in a dualvar: a dualvar inside a tree changes
the bytes the emitters write. See
L<File::SOPS::Encrypted/canonical_float_dualvar>.

The C<identities> parameter must be an ArrayRef of age secret keys (starting
with C<AGE-SECRET-KEY-1...>).

If C<format> is not specified, it will be auto-detected from the content.

Dies if none of the provided identities can decrypt the data key, or if MAC
verification does not succeed. B<Verification failing to run counts as not
succeeding>: a document whose C<sops> section has no C<mac>, or a C<mac> that
is not a well-formed C<ENC[...]> value, or one that will not decrypt under the
data key and this document's C<lastmodified>, is refused rather than returned
unverified. This mirrors the Go implementation, which reports C<File has no
MAC> / C<Cannot decrypt MAC> and stops.

C<ignore_mac> is the equivalent of the reference implementation's
C<--ignore-mac>, and the only way to read such a document. It skips
verification entirely, so what it returns is decrypted but B<not
authenticated> -- the AAD binding on each individual value still holds, but
nothing detects a value that was deleted, duplicated, moved to another key, or
replaced with one taken from elsewhere in the same document. Use it to recover
data, not to consume it.

C<max_stanzas> bounds how many age entries in the document's C<sops.age> list
this method will attempt to decrypt, and B<defaults to 64>. A document
presenting more than this is refused before any age entry is decrypted, because
each attempt costs an X25519 scalar multiplication per stanza before the age
header is authenticated -- a document carrying many entries amplifies that into
a denial of service (CVE-2026-85783). Sixty-four is deliberately conservative;
real documents carry a handful of recipients. Raise it explicitly for a document
that legitimately carries more. Passing C<undef> (or omitting it) keeps the
default, so a caller that does not set it is unaffected. This is the limit
L<File::SOPS::Backend::Age/decrypt_data_key> enforces; the value given here is
forwarded to it unchanged.

=head3 The rule decides what a value is, in both directions

B<New in 0.003, and it changes what this method returns and what it refuses.>
The document's encryption rule -- L<File::SOPS::Metadata/should_encrypt_path>,
built from C<unencrypted_suffix>, C<encrypted_suffix>, C<unencrypted_regex> or
C<encrypted_regex> -- is asked about B<every> leaf on the way out, exactly as it
is on the way in, and its answer is what decides whether a leaf is ciphertext at
all. Until 0.003 this method asked the leaf instead: anything that looked like
C<ENC[...]> was decrypted, whatever the rule said.

That is how sops reads a document, and two things follow from it.

B<A leaf the rule excludes is a literal value>, whatever its text spells. An
C<ENC[...]> string at such a path is not decrypted; it comes back as that
string, and the MAC covers that string rather than the value behind it. A
document whose rule excludes a leaf that really is encrypted therefore fails
its MAC, which is what sops does with it too (measured on 3.13.3
over four formats and all four rule fields: exit 51, I<MAC mismatch>, with the
digest taken over the C<ENC[...]> text byte for byte). It also means a plain
string of your own that happens to spell C<ENC[...]> survives a round trip
intact, as long as the rule leaves its path alone.

B<A leaf the rule selects must be encrypted>, and one that is not is refused at
its path -- because reading it as a literal meant B<encrypting> it on the next
write, turning a value that was readable into ciphertext under a data key the
caller may not keep. sops refuses the same document at exit 25. Four shapes are
left alone rather than refused, because sops leaves them alone as well: an
C<undef>, an empty string, a comment, and an empty list or mapping. The first
two are also the only shapes L</encrypt> writes bare into a slot the rule
selects.

The error message names the path and the rule and never the value: a leaf that
is bare where the rule says it is encrypted is a secret in the clear, and an
error message goes into bug reports.

C<< ignore_mac => 1 >> does not change any of this. It skips the MAC and
nothing else, so a document whose rule excludes an encrypted leaf comes back
holding that leaf's C<ENC[...]> text -- decrypted values everywhere the rule
selects, ciphertext everywhere it does not.

B<A regex rule is read here in RE2's dialect too>, which is the one place this
path is more permissive than the write path. sops does not report a pattern RE2
cannot compile: it discards the compile error, so the rule matches B<nothing>
and every value is classified as though the rule were not there. That is
reproducible and it is reproduced, so
C<< unencrypted_regex: "(?=foo)" >> -- which C<sops -e --unencrypted-regex> will
write for you without a word -- is a document this method reads at exit 0,
exactly as C<sops -d> reads it. L</encrypt> and L</rotate> still refuse to
B<write> under such a rule. What stays refused on this path is a pattern the two
dialects compile and read B<differently> (C<\v>, C<\Q>, C<\E>) or one Perl
cannot compile at all (C<(?U)>): there is no sops answer to reproduce for those,
so guessing at one would classify leaves wrongly and silently. See
F<docs/adr/0051>.

=head3 A comment in a list comes back as a C<File::SOPS::Comment>

B<New in 0.003.> sops attaches a comment to the node that B<follows> it, and
where that node is a sequence entry it writes the comment as a sequence entry of
its own (C<- ENC[...,type:comment]>) -- in YAML and, measured, in JSON written
with C<--output-type json> as well. Such an entry comes back as a
C<File::SOPS::Comment> object holding the comment's text, sitting at the index
the file puts it at. Hand the same tree back to L</encrypt> or use L</rotate>
and it is written out again as a C<type:comment> entry; C<sops -d> then restores
it as a real comment, on the node it was attached to.

It is deliberately an B<object> and not the text: a comment is not a value, and
a string here would be an extra element the file does not contain. That is what
this used to return, and a C<decrypt> plus C<encrypt> cycle made it a permanent
value with C<sops -d> reporting success at every step (k108). A comment
leaf is B<not covered by the MAC>, which is what sops does with one.

Two shapes are still refused, both naming the path: a comment in a B<mapping
value> slot, which no SOPS store writes and which sops reads back as a dump of
Go's comment struct; and writing a comment into B<plaintext>, so
L</decrypt_file> and L</edit> refuse a document that has one --
L<YAML::XS> cannot emit a comment, and a comment line handed to an editor would
be dropped on the way back in. A comment above a B<mapping key> never reaches
this library at all: it stays a comment line, which L<YAML::XS> discards on the
way in and cannot write on the way out. See
L<docs/adr/0041|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0041-a-sops-comment-is-a-leaf-of-its-own-not-a-value-and-not-a-refusal.md>.

B<New in 0.003: a I<plaintext> comment in an encrypted slot is warned about.>
Distinct from the encrypted C<type:comment> entry above: where a
C<File::SOPS::Comment> stands B<bare> in a slot the document's encryption rule
B<selects>, this method C<carp>s. That is the third of the four bare shapes
L</The rule decides what a value is, in both directions> tolerates in a selected
slot -- the document is still read, the comment comes back unchanged and stays
out of the MAC, exactly as C<sops -d> reads the same document at exit 0 and warns
the same way (its message quotes sops's own C<Found possibly unencrypted comment
in file>). The warning is advisory -- such a comment is neither encrypted nor
authenticated and may hold a secret in the clear -- and B<its text is not put in
the warning>, for that same reason: a value that lands in a log was not
encrypted for any practical purpose. Any re-encryption of the document
(L</rotate>, L</edit>, L</encrypt_in_place>, or L</decrypt_file> then
L</encrypt_file>) turns the comment into an encrypted C<type:comment> leaf and
silences it.

This reaches B<dotenv and INI only>. A plaintext comment has to survive parsing
into a C<File::SOPS::Comment> before there is anything to warn about, and
L<YAML::XS> discards one before this library sees the tree -- so a YAML document
never gets here, though C<sops> itself warns for YAML as well. See
L<docs/adr/0067|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0067-a-plaintext-comment-in-an-encrypted-slot-is-warned-about-not-silenced.md>.

=head3 A YAML literal that overflows a double comes back as a string

B<New in 0.003, and a change for existing callers.> From an B<unencrypted>
YAML slot, a literal libyaml resolves to a non-finite double -- C<1e400>, a
401-digit integer, and the bare spellings C<Inf>, C<inf>, C<INF>, C<Infinity>,
C<NaN>, C<nan>, C<NAN>, C<-Inf> and C<+Inf> -- comes back as a plain B<string>
holding the literal's own text. It used to carry C<Inf> or C<NaN> as its
numeric half as well, because L<YAML::XS> returns those literals with both
halves set.

B<This is a correction, and it does not extend to the encrypted slot.>
go-yaml -- the parser sops reads a document with -- resolves none of those
spellings to a number either: C<strconv.ParseFloat> answers C<ErrRange>, so
sops keeps a string, writes C<type:str> and digests the literal's own text. The
old return value also belonged to a document this library mostly could not read
at all: of 20 such documents C<sops -e> wrote and C<sops -d> read, 17 failed
here with C<MAC verification failed> and 3 verified by coincidence. An
B<encrypted> C<type:float> whose plaintext is C<+Inf>, C<-Inf> or C<NaN> is
B<unchanged> and still decrypts to a real Perl non-finite float, bit for bit --
measured on a document sops wrote, C<000000000000f07f>, C<000000000000f0ff> and
C<000000000000f8ff> -- because such a leaf is still an C<ENC[...]> string when
the document is parsed and cannot reach the retyping walk at all.

Arithmetic is not what changes. Perl numifies every one of those spellings to
the same double and does not warn, so C<0 + $value> answers exactly as before.
What moves is the scalar's B<type>, and with it what re-encrypting the returned
tree writes: C<type:str>, which is what sops writes for the same leaf, where
the numeric half used to hit the non-finite refusal in
L<File::SOPS::Encrypted/assert_representable>. Untouched: the twelve spellings
go-yaml really does resolve to a non-finite float (C<.inf>, C<.nan> and their
case variants -- an B<encrypted> one of those decrypts to a real C<Inf> here as
it always did, and an B<unencrypted> one is the separate repair described under
L</A plain YAML infinity is the float go-yaml reads>), and JSON, where sops
refuses the document itself. See
L<File::SOPS::Format::YAML/parse>, L</A number past Go's int64 is a float>,
k102 and
L<docs/adr/0023|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0023-a-yaml-literal-that-overflows-a-double-is-a-string-not-a-float.md>.

=head3 A document that contains itself is refused

B<New in 0.003.> A document carrying a B<recursive YAML anchor> -- one whose
value is nested inside itself -- is refused here, before the data key is
unwrapped, rather than hanging the process as it did until now. The check and
the reasoning are the same in both directions and are described under
L</A structure that contains itself is refused>.

The refusal deliberately comes B<ahead> of the key: a cyclic document reports
the cycle even when none of the C<identities> could have opened it. That is the
order sops answers in, measured -- C<sops -d> on such a file with no age
identity available reports C<yaml: anchor 'a' value contains itself>, not a
failure to get the data key.

C<ignore_mac> does not get past this. It suppresses verification, not the
document's shape.

The same holds, at the same place and in the same order, for a document whose
aliases are acyclic but exponentially shared -- see
L</A document that expands far beyond what it contains is refused>. Measured,
C<sops -d> on such a file with no age identity available reports
C<yaml: document contains excessive aliasing> rather than a failure to get the
data key, so this reports it there too. Before the guard, C<decrypt> at 15
levels walked 65,535 leaves before it could report anything at all, and with
C<ignore_mac =E<gt> 1> it walked the same tree with nothing to report.

And for a document nested deeper than this library walks -- see
L</A document nested deeper than sops can carry is refused>. Measured the same
way: C<sops -d> on an over-deep encrypted file reports
C<yaml: exceeded max depth of 10000> whether or not an age identity is
available, so the depth is reported here ahead of the key as well.

=head2 encrypt_file

    File::SOPS->encrypt_file(
        input      => 'secrets.yaml',
        output     => 'secrets.enc.yaml',  # optional, defaults to input (in-place)
        recipients => \@age_public_keys,
        format     => 'yaml',              # optional, auto-detected from filename
    );

Encrypts a file.

Reads the input file, encrypts it for the specified recipients, and writes the
encrypted content to the output file. If C<output> is not specified, encrypts
in-place (overwrites the input file) -- which is what L</encrypt_in_place>
spells out.

The output is written atomically, whether it is the input file, another file
that already exists, or a new one: the plaintext input, or whatever the output
file held before, survives a write that cannot finish. Until 0.003 it did not,
and the consequences of the C<rename> that fixed it -- a new inode, so hard
links keep the old content -- are in L</How a file is written>.

The input is read as UTF-8; see L</Character encoding>.

B<Dies if the input already has a top-level C<sops> entry> -- which is what an
already-encrypted file looks like. Until 0.003 there was no such check, and the
result destroyed data: parsing split the C<sops> section off before L</encrypt>
ever saw it, so the C<ENC[...]> strings were encrypted a second time under a
B<new> data key while the old section -- holding the key they were encrypted
with -- was discarded rather than written back. The doubly-wrapped file was
written out successfully and silently, over the original if C<output> was
omitted, and decrypting it returns the inner C<ENC[...]> strings that nothing
can now decrypt. To re-key an encrypted file use L</rotate>; to change its
contents, decrypt it first. sops refuses the same input with exit code 203.

It dies whatever that entry holds. A B<plaintext> file using the name for its
own value -- C<sops: mine>, a list, an explicit C<null> -- is refused for the
same reason and with the same exit code by sops, and until 0.003 this method
took it, dropped the key and wrote the rest back: parsing removed the entry
before deciding there was no metadata section, so the guard above never saw it
and the key was simply missing from the output. See
L<File::SOPS::Metadata/from_hash>.

Format is auto-detected from the filename extension (C<.yaml>, C<.yml>, C<.json>,
C<.env>)
unless explicitly specified.

C<mac_only_encrypted>, the four encryption rules and C<metadata> are all
passed through to L</encrypt>; see L</Choosing what gets encrypted>.

Returns true on success.

=head2 encrypt_in_place

    File::SOPS->encrypt_in_place(
        file       => 'secrets.yaml',
        recipients => \@age_public_keys,
        format     => 'yaml',   # optional, auto-detected from filename
    );

Encrypts a plaintext file over itself.

This is L</encrypt_file> with C<output> omitted, said in one argument instead
of two. There is nothing C<encrypt_file> will not do for you here -- since
0.003 both write atomically, so neither can leave the plaintext truncated or
half-encrypted (L</How a file is written>) -- but C<file> cannot be got wrong
the way an C<input>/C<output> pair can, and it is the same shape L</edit> and
L</rotate> take for the same job.

The file's permissions are preserved, it comes back with a B<new inode> so hard
links keep the old plaintext, and a symlink is resolved rather than replaced.
All three, and where they differ from sops, are in L</How a file is written>.

C<mac_only_encrypted>, the four encryption rules and C<metadata> are passed
through to L</encrypt>; see L</Choosing what gets encrypted>.

B<Dies if the file is already encrypted>, i.e. has a top-level C<sops> entry,
for the reasons in L</encrypt_file>. There is deliberately no "encrypt it
again" mode: to re-key an encrypted file use L</rotate>, to change its contents
use L</edit>. sops answers the same call the same way, with exit code 203 and
the same advice.

Returns true on success.

=head2 decrypt_file

    File::SOPS->decrypt_file(
        input      => 'secrets.enc.yaml',
        output     => 'secrets.yaml',
        identities => \@age_secret_keys,
        format     => 'yaml',  # optional, auto-detected from filename
    );

Decrypts a SOPS-encrypted file.

Reads the encrypted input file, decrypts it using the provided identities,
and writes the decrypted content to the output file.

The output is UTF-8 encoded, so a file round-tripped through L</encrypt_file>
and back is byte-identical in its non-ASCII content rather than double-encoded.
See L</Character encoding>.

It is written by the format handler's C<emit>
(L<File::SOPS::Format::YAML/emit>, L<File::SOPS::Format::JSON/emit>) -- the
same emitter the encrypted document goes through, minus the C<sops> section --
so the plaintext and the encrypted file cannot disagree about quoting, booleans,
key order or float precision. In YAML that also means it starts with the
document-start marker C<--->, which C<sops -d> does not write; the line is
cosmetic and L</Every YAML file starts with C<--->, where sops writes none> has
the measurement.

B<One rendering deliberately differs from C<sops -d>: in JSON, an integral
C<type:float> is written C<2.0> where sops writes C<2>.> The YAML output is
C<2>, exactly as C<sops -d> writes it. C<2.0> parses back as a float, so
C<decrypt_file> -> hand-edit -> L</encrypt_file> keeps such a leaf at
C<type:float>, where C<2> silently relabels it C<type:int> -- which is what
C<sops -d> followed by C<sops -e> does to its own document, and what the YAML
side therefore still does here. Measured against sops 3.13.3 on a document
sops itself wrote; see L<File::SOPS::Encrypted/decrypt_value>, k73 and
L<docs/adr/0009|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0009-a-decrypted-float-comes-back-as-a-float.md>.

B<The plaintext of a JSON number past C<2**64-1> moved in 0.003>, because such
a leaf is now a float rather than a string: an unencrypted
C<100000000000000000000> is written back bare where it used to be written as
the JSON string C<"100000000000000000000">, and an encrypted one as C<1e+20>.
Both parse back to the same double and both are what the input document meant;
what changes is that the plaintext no longer turns the reference's own number
into a string. The window below it, C<2**63> to C<2**64-1>, is written back
byte for byte as before -- what moved there is that a document whose number is
not its double's canonical decimal is now read at all, where it used to be
refused as C<MAC verification failed>, and that C<decrypt_file> then writes the
normalisation C<sops -d> writes. See
L</A number past Go's int64 is a float>.

Unlike L</encrypt_file>, C<output> is required to prevent accidental data loss.
It is nonetheless written atomically, since nothing stops it naming a file that
matters -- the encrypted input itself, or a working copy being refreshed. Until
0.003 an output that already existed was truncated before the plaintext was
written and a failing write was not reported, so a full disk replaced that file
with an empty one and C<decrypt_file> still returned true. See L</How a file is
written>, which also covers what mode the output file gets.

C<ignore_mac> is passed through to L</decrypt>; read the warning there before
using it. C<max_stanzas> is passed through to L</decrypt> as well, and defaults
to 64.

A dotenv or INI document whose encrypted slot holds a I<plaintext> comment
C<carp>s on the read, as L</decrypt> describes under L</A comment in a list comes
back as a C<File::SOPS::Comment>>; the decrypted output still carries it.

A B<multi-document> YAML stream (see L<decrypt|/A multi-document YAML stream is
an ArrayRef>) is decrypted, MAC-verified and written back out as a plaintext
multi-document YAML stream, its documents joined by C<--->.

Returns true on success.

=head2 extract

    my $value = File::SOPS->extract(
        file       => 'secrets.enc.yaml',
        path       => '["database"]["password"]',
        identities => \@age_secret_keys,
        format     => 'yaml',  # optional, auto-detected from filename
        document   => 0,       # optional, which document of a stream (default 0)
    );

Extracts and decrypts a single value from an encrypted file.

Path can be specified in two formats:

=over 4

=item * Bracket notation: C<["database"]["password"]>, C<['database']['password']>

=item * Dot notation: C<database.password>

=back

For array indices, use a bare number: C<["items"][0]> or C<items.0>. Before
0.003 the bracket parser only recognised double-quoted components, so
C<["items"][0]> matched C<items> alone and returned the whole ArrayRef.

The whole file is decrypted and MAC-verified either way. C<extract> saves you
the navigation, not the work -- it is not a cheaper L</decrypt>.
C<ignore_mac> is passed through to L</decrypt>, and so is C<max_stanzas>
(default 64).

=head3 Reaching a document of a multi-document stream

For a multi-document YAML stream (see L<decrypt|/A multi-document YAML stream is
an ArrayRef>), C<path> addresses a B<single> document and C<document> names which
one, defaulting to C<0>. The path language stays sops's, applied to the document
you name -- C<extract> does B<not> grow a document axis into the path, because
sops cannot: there a leading integer already means "the Nth key of document 0".

Two guards, both loud:

=over 4

=item * C<document> beyond the last document dies naming the file's document
count, rather than returning C<undef>.

=item * A path not found dies naming B<which document> was searched.
C<extract> never falls through to a later document looking for a key -- that
would turn a typo in C<document> into a plausible-looking answer from the wrong
one.

=back

On a single-document file, C<< document => 0 >> is a no-op and the not-found
messages are unchanged; C<< document => 1 >> there dies, because there is no
document 1. Whatever C<sops --extract '[1]["key"]'> does is not reproduced: it
panics the Go binary (docs/adr/0033 N2), and a panic is not a specification.

C<path> is a character string and is matched against the document's keys as
characters, so a non-ASCII key is written in C<path> exactly as you would write
it in C<data>. See L</Character encoding>.

Returns whatever the path names: a decrypted scalar for a leaf, or a HashRef or
ArrayRef for a branch -- C<extract(path =E<gt> '["database"]')> returns the
whole subtree, as C<sops --extract> does.

A B<float> leaf comes back as a L<Scalar::Util/dualvar>: numerically the value
itself, as a string the canonical decimal the document holds. A decrypted float
is a bare NV with no string form of its own, so printing one went through
Perl's 15 significant digits -- an encrypted C<0.30000000000000004> arrived as
C<0.3>, where C<sops -d --extract> prints all 17. Arithmetic, C<==>, C<sprintf
'%f'> and C<is_deeply> are unchanged; what changes is C<"$value">, and that
change is the point. New in 0.003; see k61 and
L<docs/adr/0010|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0010-extract-returns-a-float-that-prints-all-its-digits.md>.

Two things that dualvar does not do. The spelling is the B<wire's> -- the
canonical decimal L<File::SOPS::Encrypted/value_to_bytes> derives, which is what
the ciphertext holds and what the MAC covers, and which is B<positional at every
magnitude>. C<sops -d --extract> prints the value's YAML or JSON serialization
instead, and that switches to an exponent at the ends of the range. Measured,
sops 3.13.3, one document per row:

    format   sops prints an exponent when      example
    yaml     decimal exponent >= 6 or < -4     1000000 -> 1e+06, 1e-5 -> 1e-05
    json     decimal exponent >= 21 or < -6    1e21    -> 1e+21, 1e-7 -> 1e-7

So C<1e20> stringifies as C<100000000000000000000> here and prints as C<1e+20>
from a YAML document -- but as C<100000000000000000000> from a JSON one, where
the two agree up to 1e21. The exponent's own spelling differs between the
formats as well (C<1e-05> in YAML, C<1e-7> in JSON). B<No digits are lost in
any of it>: measured from the smallest subnormal to C<DBL_MAX>, in both
formats, every spelling either side prints parses back to the identical double.
What the positional form costs is length -- C<DBL_MAX> stringifies as 309
digits and C<5e-324> as C<0.> followed by 323 zeros and a C<5>. Matching sops
would mean a second float formatter, Go's C<%g> rules beside the C<%f> ones
this distribution has, and then a third for JSON's; the decision to keep the
wire's spelling is recorded in ADR 0010 (k79).

The wire's spelling is not the B<document's> either, where the two differ: an
unencrypted C<1.50> or C<42.0> comes back as C<1.5> and C<42>, because the
string half is the canonical decimal and not the source text.

Since 0.003 that paragraph covers a JSON number past Go's C<int64> as well:
such a leaf is a float now, where past C<2**64-1> it used to come back as a
plain string and between C<2**63> and C<2**64-1> as an exact Perl integer, so
C<extract> wraps it and prints all its digits in an encrypted slot as well as
an unencrypted one. A hand-written C<99999999999999999999> comes back as
C<100000000000000000000>, which is also what the document itself now holds.
For the lower window the digits printed are the ones the document already
carried, and it is C<0 + $value> that moved instead.
See L</A number past Go's int64 is a float>.

The second thing the dualvar does not do is travel: it applies to the B<leaf>
this method returns and to nothing else. Floats inside a returned branch are
the plain scalars they have always been, because a dualvar in a structure
changes the bytes the emitters write. Not the value: putting one into an
B<unencrypted> slot stores the canonical decimal as a number, in JSON as in
YAML (k78,
L<docs/adr/0011|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0011-a-float-leaf-that-carries-its-own-string-form-is-repaired.md>).
What changes is the spelling at the extremes -- C<1e300> written as 301
positional digits rather than C<1e+300> -- and an encrypted slot is unaffected
either way.

B<Since 0.003 a non-finite YAML literal comes back from an unencrypted slot as
a string, and is not wrapped either.> C<1e400>, a 401-digit integer and the
bare spellings C<Inf>, C<inf>, C<INF>, C<Infinity>, C<NaN>, C<nan>, C<NAN>,
C<-Inf> and C<+Inf> are the string go-yaml reads there, and a string is not a
float. This is a B<correction> -- such a leaf used to carry C<Inf> or C<NaN> as
its numeric half, on the few of those documents that could be read here at all
-- and it stops at the unencrypted slot: an B<encrypted> C<type:float> whose
plaintext is C<+Inf>, C<-Inf> or C<NaN> still comes back as the real Perl
non-finite float it always did. That one is the single float this method does
B<not> wrap, because C<+Inf> and C<NaN> are wire spellings rather than a
number's decimal, so C<"$value"> is Perl's own C<Inf> / C<NaN> and not a
canonical form. See L</A YAML literal that overflows a double comes back as a
string> under L</decrypt> and
L<File::SOPS::Encrypted/canonical_float_dualvar>.

B<Dies if the path does not exist>, at any depth, naming the component that was
not found. Before 0.003 a missing B<top-level> key returned C<undef> while a
missing nested one died, so the same mistake was silent or loud depending on
where it was made -- and C<undef> was indistinguishable from a key whose value
really is null. sops reports C<component ['nope'] not found> at every level.

=head2 rotate

    File::SOPS->rotate(
        file       => 'secrets.enc.yaml',
        identities => \@age_secret_keys,
        recipients => \@new_recipients,  # optional, keeps current recipients
        format     => 'yaml',            # optional, auto-detected from filename
    );

Rotates the data key (re-encrypts all values with a new key).

This operation:

=over 4

=item 1. Decrypts the file using C<identities>

=item 2. Generates a new random data key

=item 3. Re-encrypts all values with the new data key

=item 4. Encrypts the new data key for C<recipients> (or existing recipients if not specified)

=item 5. Writes back to the same file

=back

Step 5 is atomic: the rotated document is written next to the file and renamed
over it, so an interrupted rotation leaves the file readable under its old data
key rather than truncated. Until 0.003 the file was opened with C<< '>' >>
first, which is the worst moment to lose it -- the new data key exists only in
the buffer being written, so a file truncated there is not recoverable with any
identity. L</How a file is written> has the consequences of the C<rename>.

Key rotation is recommended periodically for security, or when removing
a recipient's access.

The rotated file keeps the C<sops> section it had, apart from what a new data
key necessarily replaces. Its encryption rules, C<mac_only_encrypted> and any
field this distribution does not model -- C<shamir_threshold> and whatever a
later sops adds -- are carried over; the wrapped data keys, the MAC and
C<lastmodified> are regenerated. Until 0.003 none of that was carried: rotate
called L</encrypt>, which built fresh metadata with the defaults, so a file
that customised any of it was rewritten under the default rules.

The values keep their C<type:> labels too, and C<type:float> on a B<whole
number> is the one that did not. Rotation re-encrypts every leaf, so each label
is re-derived from the scalar the decryption produced, and until 0.003 that
scalar came back carrying Perl's public C<SVf_IOK> whenever the plaintext was
integral: a C<whole: 2.0> that sops itself had written was rotated back out as
C<type:int>, at exit 0 and with the MAC holding either way, because the
plaintext is C<2> under both labels. What moved was the document's own type
field, silently. L<File::SOPS::Encrypted/decrypt_value> has the conversion this
now uses instead. See k73 and
L<docs/adr/0009|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0009-a-decrypted-float-comes-back-as-a-float.md>.

=head3 Files rotate refuses

Rotation makes a new data key, and this distribution can only wrap one for age
recipients. A file whose C<sops> section holds key material for another
backend -- C<pgp>, C<kms>, C<gcp_kms>, C<azure_kv>, C<hc_vault> or
C<key_groups> -- is therefore B<refused> rather than rotated:

    Refusing to rotate 'shared.yaml': its sops section holds key material
    this distribution cannot re-encrypt (pgp). ...

Both alternatives are wrong and the quiet one is worse. Dropping those entries
-- which is what happened before 0.003 -- revokes access for everyone behind
them while reporting success, and the file still decrypts perfectly for
whoever runs the command, so nothing looks amiss until someone else needs it.
Keeping them would leave a wrapped copy of a key that no longer decrypts
anything. Rotate such a file with the sops CLI, which can re-encrypt for every
backend; or, if losing those recipients is the intention, say so by calling
L</decrypt> and L</encrypt> yourself.

The second refusal is the document's own encryption rule, where that rule is a
regex Go RE2 and Perl do not read the same way. Rotation B<writes>, and this
distribution does not write a document under a rule it cannot apply as sops
applies it -- see
L<File::SOPS::Metadata/The regex rules are matched in RE2's dialect>. Note the
asymmetry, which is deliberate and is F<docs/adr/0051>: L</decrypt> and
L</extract> B<do> read such a document where sops's own answer is reproducible,
so a file this method refuses to rotate is still one you can read, and
L</decrypt> followed by L</encrypt> under a rewritten pattern is the way
through.

=head3 A rule that does not cover what is encrypted stops on the MAC

B<Changed in 0.003, and it changed twice.> A rotation re-encrypts the document
under the rule the document itself carries, and that rule has to be the one the
document is B<already> encrypted under. Where a leaf is encrypted in the file
and the rule says it is not, this method used to write that value back into the
file B<in plaintext>, at exit 0 -- L</decrypt> was driven by which values looked
encrypted and returned the plaintext of all of them, L</encrypt> was driven by
the rule and encrypted only what the rule selected, and everything in between
went to disk bare.

That cannot happen any more, and not because a guard stands in the way. The
decryption L</rotate> does first is B<rule-first> now, so a leaf the rule
excludes is never decrypted at all: what comes back is its own C<ENC[...]>
text, and what gets written is that same text. There is no plaintext for this
method to leak. What stops such a document is the MAC, in L</decrypt>, which is
exactly where sops stops it -- and it is stopped because the digest covers the
C<ENC[...]> text rather than the value behind it. See
L</The rule decides what a value is, in both directions>.

The refusal an intermediate release raised here, naming the leaf and the rule,
is gone with the guard that raised it. It refused two documents the MAC does
not, and sops reads both: one whose stored MAC really is over the literal, and
-- under C<< ignore_mac => 1 >> -- any of them.

C<ignore_mac> is passed through to L</decrypt>; rotating a file you could not
verify re-signs whatever it contained, so prefer to fail. C<max_stanzas> is
passed through to L</decrypt> as well, and defaults to 64.

A dotenv or INI document whose encrypted slot holds a I<plaintext> comment
C<carp>s on the L</decrypt> this does first (see L</A comment in a list comes
back as a C<File::SOPS::Comment>>); the rotation then re-encrypts that comment
into a C<type:comment> leaf, so a second rotation is silent.

Returns true on success.

=head2 edit

    File::SOPS->edit(
        file       => 'secrets.enc.yaml',
        identities => \@age_secret_keys,
        editor     => 'vim',   # optional, defaults to $ENV{EDITOR}
        format     => 'yaml',  # optional, auto-detected from filename
    );

Decrypts a file, opens it in an editor, and re-encrypts what comes back.

The decrypted document is written to a fresh temporary directory (mode C<0700>)
as a file (mode C<0600>) with the same basename as the original, the editor is
run on it, and the result is parsed and encrypted back over the original --
atomically, as L</encrypt_in_place> does, and for the same reason.

That is the same shape sops uses, and it has the same caveat: B<the plaintext
touches the filesystem>. Point C<TMPDIR> at a C<tmpfs> if that matters to you.

B<The decrypted copy is removed on every way out of this method>, which is
three of them:

=over 4

=item * Returning, or dying anywhere -- including from the editor failing, the
result not parsing, or the re-encryption refusing. The directory belongs to a
L<File::Temp> object scoped to the call, so unwinding removes it.

=item * C<SIGTERM> and C<SIGHUP>, which are caught for the duration of the
call, remove the directory and are then re-raised with the default disposition,
so the process still dies of the signal it was sent. Perl defers a signal that
arrives while the editor is running until the editor exits, so this happens on
the way back rather than immediately.

=item * C<Ctrl-C>, which does not reach here at all: Perl's C<system> ignores
C<SIGINT> for the duration of the child, so the interrupt goes to the editor.
The editor dying of it is an editor that exited non-zero, which is the first
case again -- reported as C<was killed by signal 2> with the file unchanged.

=back

Returns 1 if the file was rewritten, and B<0 if the editor left the content
byte-identical> -- in which case the file is not touched at all, so its
C<lastmodified>, MAC and wrapped data keys stay as they were. sops reports the
same situation as C<File has not changed, exiting.> with exit code 200.

=head3 The editor

C<editor> may be a string, which is split into words the way a shell would
(C<< editor => 'code --wait' >>), or an ArrayRef, which is used as it stands.
It defaults to C<$ENV{EDITOR}>, and the temporary file's path is appended as
the final argument. The editor is run without a shell.

B<Dies if neither is set.> sops falls back to C<vim>, C<nano> or C<vi> here;
this method does not, because a library that opens an interactive editor
nobody asked for hangs an unattended script rather than failing it.

B<Dies if the editor exits non-zero>, naming the status or the signal, and
leaves the file unchanged -- an editor that refused to start or was killed
has not produced an edit worth encrypting. sops behaves the same way
(C<Could not run editor: exit status 3>, exit code 201).

=head3 What comes back is checked before anything is written

The edited text must parse, as one document, to a mapping, and must not carry
a top-level C<sops> entry of its own. Any of those dies with the original file
untouched.

Those are two refusals, not one, and they say so: an entry of your own under
that name is refused as a reserved key -- whatever shape it has, a mapping, a
scalar, a list or an explicit C<null> -- and never as a parse failure, because
such a document parses perfectly well. sops separates the same two cases in
its editor mode, as C<Tree not valid for encryption> against C<Could not load
tree, probably due to invalid syntax>.

B<A document that does not parse is lost.> The temporary file is removed on the
way out, so the only copy of what was typed is whatever the editor still has in
its buffer. This is the one place where sops does better: it reopens the editor
on the same file until the document parses, which needs a terminal to return
to and an interactive user in front of it -- neither of which a library method
can assume.

=head3 Editing re-keys the file

Unlike C<sops edit>, which keeps the document's data key and only rewrites the
values, this method decrypts and encrypts, so the file comes back with a
B<new data key> -- the wrapped copies in the C<sops> section change on every
edit, and so does the diff. Nothing is lost by it: the age recipients and the
encryption policy (the rules, C<mac_only_encrypted>, and any C<sops> field this
distribution does not model) are carried over exactly as L</rotate> carries
them.

What it does mean is that C<edit> refuses the same files L</rotate> refuses: a
document whose C<sops> section also holds C<pgp>, C<kms>, C<gcp_kms>,
C<azure_kv>, C<hc_vault> or C<key_groups> material cannot be re-encrypted for
those recipients here, and dropping them silently would revoke their access
while reporting success. See L</Files rotate refuses>.

It stops on the other of rotate's files too, and B<before the editor is
opened>: a document holding an encrypted value at a path its own encryption
rule says is not encrypted fails its MAC in the L</decrypt> this method does
first. See L</A rule that does not cover what is encrypted stops on the MAC>.
Stopping after the editor had run would throw away what was just typed, for a
defect that was in the file before it started.

Key B<order> is not preserved either: the plaintext handed to the editor is
emitted from a Perl hash, so it comes out sorted whatever order the encrypted
file had. That is the same emitter L</decrypt_file> uses -- the format
handler's C<emit>, which is also what the encrypted document is written with --
and it is the order this distribution writes documents in anyway, so it does
not affect the MAC.

C<ignore_mac> is passed through to L</decrypt>; editing a file you could not
verify re-signs whatever it contained, so prefer to fail. C<max_stanzas> is
passed through to L</decrypt> as well, and defaults to 64.

A dotenv or INI document whose encrypted slot holds a I<plaintext> comment
C<carp>s on the L</decrypt> this does first (see L</A comment in a list comes
back as a C<File::SOPS::Comment>>); re-keying the file then re-encrypts that
comment into a C<type:comment> leaf.

=head3 What the round trip through the editor keeps, and what it does not

The document the editor sees is B<plaintext>, so anything a value knew that its
plaintext spelling does not say is gone by the time it comes back. What comes
back is parsed exactly as any other YAML file would be -- there is no second,
gentler parse for text this method wrote itself.

That is enough for a B<plain YAML infinity>, because the plaintext really does
say it: C<.inf> written plain is a float to go-yaml and to L</decrypt_file>'s
output alike, so a document sops wrote with a bare C<.inf> in an unencrypted
slot survives an edit and comes back with the wire byte-identical. Before
0.003 it did not -- editing any other key in such a file died with the leaf
refused, B<and the edit was destroyed with it>, because the temporary file is
already gone by then. See L</A plain YAML infinity is the float go-yaml reads>
and k123.

It is B<not> enough for a non-finite float in an B<encrypted> slot, and that
one is still wrong: such a leaf decrypts to a real Perl infinity, whose only
plaintext spelling from this emitter is a bare C<Inf> / C<-Inf> / C<NaN> --
tokens go-yaml reads as B<strings>. The editor is shown C<Inf>, the string
C<Inf> comes back, and the leaf is re-encrypted as a C<type:str>. C<sops edit>
keeps it a C<type:float>, measured. The file is written and nothing is said, so
this is the one place C<edit> can still lose a value quietly. Open as k134.

A C<data_key =E<gt> $bytes> argument would close the gap -- pass the
existing data key through and this method stops re-keying -- but it puts
raw key material on the public API, which is a real decision (and
probably an ADR) rather than a refactor. It will be worth doing once a
backend other than age exists (k39): today the refusal only fires
on documents this distribution could not have produced in the first
place.

=head2 creation_rules_for

    my %args = File::SOPS->creation_rules_for(file => 'secrets/prod.yaml');

    File::SOPS->encrypt_in_place(
        file => 'secrets/prod.yaml',
        %args,
    );

Reads the C<.sops.yaml> that governs a file and returns the L</encrypt>
arguments its first matching creation rule asks for: C<recipients>, plus
whichever of the four encryption rules and C<mac_only_encrypted> that rule
carries. The returned list is meant to be splatted straight into L</encrypt>,
L</encrypt_file> or L</encrypt_in_place>, which is where the actual encrypting
still happens -- this method decides B<for whom and under which rules>, and
nothing else.

Nothing here reads C<.sops.yaml> implicitly. C<encrypt> and friends still want
their C<recipients> spelled out; this is the one method that will go and look.

=head3 Finding the config file

C<.sops.yaml> is looked for in the directory holding C<file> and then in every
directory above it, up to the filesystem root, and the first one found is used.
Nothing stops the walk earlier -- not a C<.git> directory, not C<$HOME> --
which is what sops does as well (measured on 3.13.3). The name must be exactly
C<.sops.yaml>: a C<.sops.yml> is ignored there and here.

B<This is a deliberate deviation, and it is the one thing here that differs
from the reference implementation.> sops walks up from the B<current working
directory>, not from the file: measured on 3.13.3, C<sops -e a/b/c/secrets.yaml>
run from the top of that tree does not see an C<a/b/.sops.yaml> at all, and
C<sops -e /abs/path/secrets.yaml> run from an unrelated directory reports
C<config file not found> however many config files sit above the file. That is
a sensible rule for a command a person types in the directory they are working
in, and a useless one for a library: the caller's working directory has nothing
to do with the file it was handed, and a daemon whose cwd is C</> would find
nothing at all. The two agree in the ordinary case -- one C<.sops.yaml> at the
top of a repository, the file somewhere underneath it -- and differ only when
config files are nested, where walking up from the file picks the nearer and
more specific one. The measurements and the two rejected alternatives are in
L<docs/adr/0007|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0007-the-config-search-starts-at-the-file-not-at-the-working-directory.md>.

C<config> names a config file explicitly, and skips the search entirely. It is
the equivalent of sops's C<--config>. Its value is B<not> taken from
C<$SOPS_CONFIG>, which sops does honour: an environment variable that
redirects which public keys a secret gets encrypted to is a reasonable thing
for a user to set for a command they are running, and not a reasonable thing
for a library to obey on behalf of a caller who never asked. Pass
C<< config => $ENV{SOPS_CONFIG} >> if you want it.

=head3 Which rule matches

The rules are tried in order and B<the first match wins>; a rule with no
C<path_regex> matches everything, which is how a catch-all is written at the
end of the list. Both are sops's behaviour.

B<C<path_regex> is not matched against the path you passed.> It is matched
against that path made absolute and normalised, and then taken relative to the
directory holding the config file -- so with a config at the top of a
repository, a rule matches C<secrets/prod.yaml> whether the caller said
C<secrets/prod.yaml>, C<./secrets//prod.yaml>, C<../repo/secrets/prod.yaml> or
the full absolute path, and whether it is called from the top of the repository
or from inside C<secrets/>. Symlinks are B<not> resolved, so a rule sees the
link's path and not the target's. All of that is measured against sops 3.13.3,
including the fallback: a file that is not under the config file's directory at
all -- only reachable by passing C<config> here -- is matched as an absolute
path instead of as a C<../..>-prefixed relative one.

The regex is a B<Perl> regex, and nothing translates it. sops compiles the same
string with Go's RE2, which is not the same dialect: C<(?i)> works in both, but
a lookbehind compiles here and makes sops stop with C<error parsing regexp>
(measured on 3.13.3). A C<path_regex> written in either dialect alone will
therefore pick different rules -- or no rule -- depending on which of the two
tools reads the config. The constructs that RE2 does not have -- lookarounds
(C<< (?= >>, C<< (?! >>, C<< (?<= >>, C<< (?<! >>) and backreferences
(C<\1>..C<\9>) -- are refused here at match time, naming the offending
construct and the config file; everything that compiles in both
(C<(?i)>, C<.>, standard quantifiers, character classes, anchors) passes.
One that will not compile at all is reported here naming the config file
and the rule; sops reports it too. Keep a C<path_regex> to what both
accept, and you can rely on the refusal rather than on memorising the
dialect differences.

=head3 Rules this refuses rather than half-applies

Each of these dies, naming the config file and which rule in it:

=over 4

=item * A rule naming B<key material for a backend other than age> --
C<pgp>, C<kms>, C<gcp_kms>, C<azure_keyvault>, C<hc_vault_transit_uri> -- or
C<key_groups> or C<shamir_threshold>. sops wraps the data key for every backend
the rule names; age is the only one implemented here, so honouring such a rule
would write a document the config says several parties can read and only the
age recipients actually can, and report success. This is the refusal
L</rotate> makes for the same reason. Those are the config file's field names
and not the C<sops> section's, which differ.

=item * A rule carrying B<more than one encryption rule>. sops refuses the
same config with C<cannot use more than one of encrypted_suffix,
unencrypted_suffix, ... for the same rule>, and L<File::SOPS::Metadata> refuses
the resulting document; catching it here names the config file instead of the
document that could not be built.

=item * A rule carrying C<unencrypted_comment_regex> or
C<encrypted_comment_regex>. Neither parser here keeps comments, so every value
would be classified wrongly -- the refusal L</encrypt> makes for a document
carrying one.

=item * A matching rule with B<no age recipient>, which leaves nothing to
encrypt for. sops stops on the same rule with C<Could not generate data key:
[empty key group provided]>.

=back

Not finding a config file at all, and finding one where no rule matches, die
too rather than returning an empty list: both are what sops exits non-zero on,
and a C<recipients> that quietly came back empty would be a document nobody can
decrypt -- or, since L</encrypt> refuses an empty recipient list, an error
naming neither the file nor the config that failed to produce one.

=head3 The rule's own fields

C<age> is a comma-separated list of recipients, or a YAML list of them, or a
list whose entries are themselves comma-separated. Whitespace around each
recipient is ignored, which is what makes the folded

    age: >-
      age1...,
      age1...

form work. Newlines are B<not> separators on their own: measured on 3.13.3, a
literal block of recipients without commas is handed to age as one string and
fails.

C<unencrypted_suffix>, C<encrypted_suffix>, C<unencrypted_regex>,
C<encrypted_regex> and C<mac_only_encrypted> are returned as the L</encrypt>
arguments of the same names -- see L</Choosing what gets encrypted>. Fields
this does not know are ignored, as sops ignores them.

Note what the returned rules do B<not> do: nothing is applied here. A caller
that drops the encryption rule out of C<%args> encrypts under the default
instead, and a caller that adds one of its own alongside gets the refusal
L<File::SOPS::Metadata/Encryption rules are mutually exclusive> gives any
document carrying two.

=head3 What this does not read or return

A few things a C<.sops.yaml> can carry are deliberately outside this
method's scope (k54):

=over 4

=item * C<destination_rules> is not read. sops's full file lifecycle has
two rule lists, creation_rules (which decides how a file is encrypted)
and destination_rules (which decides how it is rewritten when it is
moved to a different path or backend). File::SOPS does not move files,
so destination_rules has no consumer here; a config carrying only
destination_rules is reported as having no creation rules.

=item * A rule naming C<aws_kms>, C<azure_kv> or C<hc_vault> is ignored.
Those are C<sops>-section field names that sops also ignores in a
creation rule (measured, 3.13.3). The names THIS method refuses are the
config file's: C<pgp>, C<kms>, C<gcp_kms>, C<azure_keyvault>,
C<hc_vault_transit_uri>.

=item * C<$SOPS_CONFIG> is not consulted (covered above under
C<config>).

=back

=head1 SEE ALSO

=over 4

=item * L<File::SOPS::Format::ENV> - the dotenv format handler, its flat
metadata section and its comment leaves

=item * L<File::SOPS::Format::INI> - the INI format handler, its two-level tree
and the section a comment belongs to

=item * L<File::SOPS::Encrypted> - Encrypted value parsing and generation

=item * L<File::SOPS::Metadata> - SOPS metadata section handling

=item * L<File::SOPS::Backend::Age> - Age encryption backend

=item * L<Crypt::Age> - Perl age encryption implementation

=item * L<https://github.com/getsops/sops> - Reference SOPS implementation in Go

=item * L<https://age-encryption.org/> - age encryption specification

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-file-sops/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
