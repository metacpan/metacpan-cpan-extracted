package Mail::GPG;

$VERSION = "1.0.10";

use strict;
use Carp;
use IO::Handle;
use Data::Dumper ();
use GnuPG::Interface;
use MIME::Parser;
use Mail::GPG::Result;
use Mail::Address;
use File::Temp;
use List::MoreUtils ();

$Mail::GPG::SKIP_EVENT = $ENV{MAIL_GPG_SKIP_EVENT}
    unless defined $Mail::GPG::SKIP_EVENT;

my $HAS_EVENT = 0;
$Mail::GPG::SKIP_EVENT || eval { use Event; $HAS_EVENT = 1 };

sub get_default_key_id		{ shift->{default_key_id}		}
sub get_default_passphrase	{ shift->{default_passphrase}		}
sub get_debug			{ shift->{debug}			}
sub get_debug_dir		{ shift->{debug_dir}			}
sub get_gnupg_hash_init		{ shift->{gnupg_hash_init}		}
sub get_digest			{ shift->{digest}			}
sub get_default_key_encrypt	{ shift->{default_key_encrypt}		}
sub get_gpg_call		{ shift->{gpg_call}			}
sub get_no_strict_7bit_encoding	{ shift->{no_strict_7bit_encoding}	}
sub get_use_long_key_ids        { shift->{use_long_key_ids}             }

sub set_default_key_id		{ shift->{default_key_id}	= $_[1]	}
sub set_default_passphrase	{ shift->{default_passphrase}	= $_[1]	}
sub set_debug			{ shift->{debug}		= $_[1]	}
sub set_debug_dir		{ shift->{debug_dir}		= $_[1]	}
sub set_gnupg_hash_init		{ shift->{gnupg_hash_init}	= $_[1]	}
sub set_digest			{ shift->{digest}		= $_[1]	}
sub set_default_key_encrypt	{ shift->{default_key_encrypt}	= $_[1]	}
sub set_gpg_call		{ shift->{gpg_call}		= $_[1]	}
sub set_no_strict_7bit_encoding	{ shift->{no_strict_7bit_encoding}=$_[1]}
sub set_use_long_key_ids        { shift->{use_long_key_ids}     = $_[1] }

sub new {
    my $class = shift;
    my %par   = @_;
    my  ($default_key_id, $default_passphrase, $debug, $debug_dir) =
    @par{'default_key_id','default_passphrase','debug','debug_dir'};
    my  ($gnupg_hash_init, $digest, $gpg_call, $default_key_encrypt) =
    @par{'gnupg_hash_init','digest','gpg_call','default_key_encrypt'};
    my  ($no_strict_7bit_encoding, $use_long_key_ids) =
    @par{'no_strict_7bit_encoding','use_long_key_ids'};

    $debug_dir               ||= $ENV{DUMPDIR} || File::Spec->tmpdir . '/mail-gpg-test';
    $gnupg_hash_init         ||= {};
    $digest                  ||= "RIPEMD160";
    $gpg_call                ||= "gpg";
    $no_strict_7bit_encoding ||= 0;
    $use_long_key_ids        ||= 0;

    my $self = bless {
        default_key_id          => $default_key_id,
        default_passphrase      => $default_passphrase,
        debug                   => $debug,
        debug_dir               => $debug_dir,
        gnupg_hash_init         => $gnupg_hash_init,
        digest                  => $digest,
        default_key_encrypt     => $default_key_encrypt,
        gpg_call                => $gpg_call,
        no_strict_7bit_encoding => $no_strict_7bit_encoding,
        use_long_key_ids        => $use_long_key_ids,
    }, $class;

    return $self;
}

sub new_gpg_interface {
    my $self = shift;
    my %par  = @_;
    my ($options, $passphrase) = @par{'options','passphrase'};

    my $gpg = GnuPG::Interface->new;

    $gpg->passphrase($passphrase) if defined $passphrase;
    $gpg->call( $self->get_gpg_call ) if $self->get_gpg_call ne '';

    my $gnupg_hash_init = $self->get_gnupg_hash_init;

    if ($options) {
        $gpg->options->hash_init( %{$options}, %{$gnupg_hash_init} );
    }
    else {
        $gpg->options->hash_init( %{$gnupg_hash_init} );
    }

    $gpg->options->push_extra_args( '--digest', $self->get_digest );
    $gpg->options->meta_interactive(0);

    return $gpg;
}

sub save_debug_file {
    my $self = shift;
    my %par  = @_;
    my ($name, $data, $data_fh ) = @par{'name','data','data_fh' };

    $name = $self->get_debug_dir . "/mgpg-" . $name;

    open( DBG, ">$name" ) or die "can't write $name";
    if ($data_fh) {
        seek $data_fh, 0, 0;
        print DBG $_ while <$data_fh>;
    }
    elsif ( ref $data ) {
        print DBG $$data;
    }
    else {
        print DBG $data;
    }
    close DBG;

    1;
}

sub check_7bit_encoding_of_all_parts {
    my $self     = shift;
    my %par      = @_;
    my ($entity) = $par{'entity'};

    #-- skip if no strict encoding check should be applied
    return 1 if $self->get_no_strict_7bit_encoding;

    #-- first the primary entity
    my $encoding = $entity->head->get("content-transfer-encoding");
    die "Content transfer encoding '$encoding' is not 7bit safe"
        unless not defined $encoding
        or $encoding =~ /^(quoted-printable|base64|7bit)\s*$/i;

    #-- now all parts
    return 1 if not $entity->parts;

    #-- recursively
    my $parts = $entity->parts;
    for ( my $i = 0; $i < $parts; ++$i ) {
        $self->check_7bit_encoding_of_all_parts( entity => $entity->parts($i),
        );
    }

    return 1;
}

sub check_encryption {
    my $self = shift;
    my %par  = @_;
    my  ($entity, $encrypted_text_sref) =
    @par{'entity','encrypted_text_sref'};

    my $is_armor;
    if ( $entity->effective_type =~ m!multipart/encrypted!i ) {

        #-- is this a valid RFC 3156 multipart/encrypted entity?
        die "Entity must have two parts"
            if $entity->parts != 2;
        die "Entity is not OpenPGP encrypted"
            unless $entity->parts(0)->effective_type
            =~ m!application/pgp-encrypted!i;
        $$encrypted_text_sref = $entity->parts(1)->body_as_string;

    }
    elsif ( $entity->bodyhandle ) {

        #-- probably an ASCII armor encrypted entity
        #-- (we need the *decoded* data here - hopefully the
        #--  MIME::Parser had decode_body(1) set).
        $$encrypted_text_sref = $entity->bodyhandle->as_string;
        die "Entity is not OpenPGP encrypted"
            unless $$encrypted_text_sref =~ /^-----BEGIN PGP MESSAGE-----/m;
        $is_armor = 1;
    }
    else {
        die "Entity is not multipart/encrypted and has no body";
    }

    return $is_armor;
}

sub perform_multiplexed_gpg_io {
    $HAS_EVENT ? perform_multiplexed_gpg_io_event(@_) :
                 perform_multiplexed_gpg_io_select(@_);
}

sub perform_multiplexed_gpg_io_select {
    my $self = shift;
    my %par  = @_;
    my  ($data_fh, $data_canonify, $stdin_fh, $stderr_fh) =
    @par{'data_fh','data_canonify','stdin_fh','stderr_fh'};
    my  ($stdout_fh, $status_fh, $stderr_sref, $stdout_sref) =
    @par{'stdout_fh','status_fh','stderr_sref','stdout_sref'};
    my  ($status_sref) =
    $par{'status_sref'};

    require IO::Select;

    #-- perl < 5.6 compatibility: seek() and read() work
    #-- on native GLOB filehandle only, so dertmine type
    #-- of filehandle here
    my $data_fh_glob = ref $data_fh eq 'GLOB';

    #-- rewind the data filehandle
    if ($data_fh_glob) {
        seek $data_fh, 0, 0;
    }
    else {
        $data_fh->seek( 0, 0 );
    }

    #-- create IO::Select objects for all
    #-- filehandles in question
    my $stdin  = IO::Select->new($stdin_fh);
    my $stderr = IO::Select->new($stderr_fh);
    my $stdout = IO::Select->new($stdout_fh);
    my $status = $status_fh ? IO::Select->new($status_fh) : undef;

    my $buffer;
    while (1) {

        #-- as long we has data try to write
        #-- it into gpg
        while ( $data_fh && $stdin->can_write(0.1) ) {
            if ( $data_fh_glob
                ? read $data_fh,
                $buffer, 1024
                : $data_fh->read( $buffer, 1024 ) ) {

                #-- ok, got a block of data
                if ($data_canonify) {

                    #-- canonify it if requested
                    $buffer =~ s/\x0A/\x0D\x0A/g;
                    $buffer =~ s/\x0D\x0D\x0A/\x0D\x0A/g;
                }

                #-- feed it into gpg
                print $stdin_fh $buffer;
            }
            else {

                #-- no data read, close gpg's stdin
                #-- and set the data filehandle to false
                close $stdin_fh;
                $data_fh = 0;
            }
        }

        #-- probably we can read from gpg's stdout
        while ( $stdout->can_read(0.1) ) {
            last if eof($stdout_fh);
            $$stdout_sref .= <$stdout_fh>;
        }

        #-- probably we can read from gpg's stderr
        while ( $stderr->can_read(0.1) ) {
            last if eof($stderr_fh);
            $$stderr_sref .= <$stderr_fh>;
        }

        #-- probably we can read from gpg's status
        if ($status) {
            while ( $status->can_read(0.1) ) {
                last if eof($status_fh);
                $$status_sref .= <$status_fh>;
            }
        }

        #-- we're finished if no more data left
        #-- and both gpg's stdout and stderr
        #-- are at eof.
        return
            if !$data_fh
            && eof($stderr_fh)
            && eof($stdout_fh)
            && ( !$status_fh || eof($status_fh) );
    }

    1;
}

sub perform_multiplexed_gpg_io_event {
    my $self = shift;
    my %par  = @_;
    my  ($data_fh, $data_canonify, $stdin_fh, $stderr_fh) =
    @par{'data_fh','data_canonify','stdin_fh','stderr_fh'};
    my  ($stdout_fh, $status_fh, $stderr_sref, $stdout_sref) =
    @par{'stdout_fh','status_fh','stderr_sref','stdout_sref'};
    my  ($status_sref) =
    $par{'status_sref'};

    #-- perl < 5.6 compatibility: seek() and read() work
    #-- on native GLOB filehandle only, so dertmine type
    #-- of filehandle here
    my $data_fh_glob = ref $data_fh eq 'GLOB';

    #-- rewind the data filehandle
    if ($data_fh_glob) {
        seek $data_fh, 0, 0;
    }
    else {
        $data_fh->seek( 0, 0 );
    }

    my $data_buffer = "";

    my ($data_watcher, $stdin_watcher, $stderr_watcher,
        $stdout_watcher, $status_watcher);

    $data_watcher = Event->io (
        fd   => $data_fh,
        poll => 're',
        desc => "data ($data_fh)",
        cb   => sub {
            my $buffer;
            my $rc = sysread($data_fh, $buffer, 4096);

            if ( $data_canonify ) {
                #-- canonify it if requested
                $buffer =~ s/\x0A/\x0D\x0A/g;
                $buffer =~ s/\x0D\x0D\x0A/\x0D\x0A/g;
            }
            
            $data_buffer .= $buffer;
            
            $stdin_watcher->start
                if $data_buffer ne '' and !$stdin_watcher->is_active;

            if ( !$rc ) {
                $data_watcher->cancel;
                $data_watcher = undef;
                $stdin_watcher->cancel if $data_buffer eq '';
                close $stdin_fh if $data_buffer eq '';
                return;
            }
        },
    );

    $stdin_watcher = Event->io (
        fd   => $stdin_fh,
        poll => 'we',
        cb   => sub {
            my $written = syswrite($stdin_fh, $data_buffer, length($data_buffer));
            if ( not defined $written ) {
                $stdin_watcher->cancel;
                close $stdin_fh;
                $data_watcher->cancel;
                $stderr_watcher->cancel;
                $stdout_watcher->cancel;
                $status_watcher->cancel;
                Event::unloop();
                return;
            }
            $data_buffer = substr($data_buffer, $written) if $written;
            if ( $data_buffer eq '' && !$data_watcher ) {
                $stdin_watcher->cancel;
                close $stdin_fh;
            }
            elsif ( $data_buffer eq '' ) {
                $stdin_watcher->stop;
            }
        },
    );
    $stdin_watcher->stop;

    $stderr_watcher = Event->io (
        fd   => $stderr_fh,
        poll => 're',
        cb   => sub {
            my $rc = sysread(
                $stderr_fh,
                ${$stderr_sref},
                4096,
                length(${$stderr_sref})
            );
            $stderr_watcher->cancel unless $rc;
        },
    );

    $stdout_watcher = Event->io (
        fd   => $stdout_fh,
        poll => 're',
        cb   => sub {
            my $rc = sysread(
                $stdout_fh,
                ${$stdout_sref},
                4096,
                length(${$stdout_sref})
            );
            $stdout_watcher->cancel unless $rc;
        },
    );

    if ( $status_fh ) {
        $status_watcher = Event->io (
            fd   => $status_fh,
            poll => 're',
            cb   => sub {
                my $rc = sysread(
                    $status_fh,
                    ${$status_sref},
                    4096,
                    length(${$status_sref})
                );
                $status_watcher->cancel unless $rc;
            },
        );
    }

    Event::loop();

    1;
}



#-- Addresses bug:     https://rt.cpan.org/Public/Bug/Display.html?id=103828  (here)
#-- Possibly also:     https://rt.cpan.org/Public/Bug/Display.html?id=81082   (here)
#                  and https://rt.cpan.org/Public/Bug/Display.html?id=80500   (in Makefile.PL)

sub _parse_key_list {
  my $self = shift;
  my ($output_stdout, %par) = @_;
  my  ($coerce, $debug, $verbose) =
  @par{'coerce','debug','verbose'};

  #-- grab key ID's and emails from output (backward compatible to gpg 1.x)
  #
  #  Example:
  #  search request: "--list-keys --with-colons 6C187D0F196ED9E3"
  #  format        : see /usr/share/doc/packages/gpg2/DETAILS
  #
  #--OLD sample: gpg (GnuPG) 1.4.11
  #   tru:t:1:1431088683:0:3:1:5
  #   pub:-:1024:17:062F00DAE20F5035:2004-02-10:::-:Jörn Reder Mail\x3a\x3aGPG Test Key <mailgpg@localdomain>::scaESCA:
  #   sub:-:1024:16:6C187D0F196ED9E3:2004-02-10::::::e:
  #
  #   expected output: (062F00DAE20F5035, 'Jörn Reder Mail::GPG Test Key <mailgpg@localdomain>')
  #
  #--NEW sample: gpg (GnuPG) 2.0.22
  #  tru:t:1:1429473192:0:3:1:5
  #  pub:-:1024:17:062F00DAE20F5035:1076425915:::-:::scaESCA:
  #  uid:-::::1076425915::588869ADE077B8FB05788A99565AEED15AED8231::Jörn Reder Mail\x3a\x3aGPG Test Key <mailgpg@localdomain>:
  #  sub:-:1024:16:6C187D0F196ED9E3:1076425917::::::e:
  #
  #  expected output: (062F00DAE20F5035, 'Jörn Reder Mail::GPG Test Key <mailgpg@localdomain>',
  #                    6C187D0F196ED9E3, 'Jörn Reder Mail::GPG Test Key <mailgpg@localdomain>')
  #
  #  PERLBOTIX<ätt>cpan.org / May, 2015

  my @result;

  #-- needed for utf8 handling
  require Encode if $] >= 5.008;

  $output_stdout .= "\nFLUSH\n"; #-- we add this token to trigger flushing of the last record

  #-- these values are valid per "paragraph" (from pub: to pub:)
  my @ids;                       #-- list of potential IDs (pub, sub)
  my @emails;                    #-- list of potential email adresses (uid)
  my $gpg2_mode = 0;             #-- auto-detect OLD/NEW format: true if NEW (gpg2) format

  #-- parse output line by line
  #--  OLD-format (gpg 1.x): simulate old behaviour
  #--  NEW-format (gpg 2.x): create all combinations of valid key-IDs and emails; return (pub) key-ID first,
  #    so the result stays backward compatible

  while (  $output_stdout =~ m!^((\w+):?.*?)[\r\n]+!mg  ) {

    my ($line, $tag) = ($1, $2);
    my @fields       = split /:/, $line, -1;

    warn("\nFields: ", join(", ", map { "($_)" } @fields)) if $debug;

    #-- skip entries that are expired or otherwise invalid
    if (     ( $fields[1]  and  $fields[1]  =~ /^([eird])$/ )
          or ( $fields[11] and  $fields[11] =~ /([D])/      )
       ) { #-- cannot use key (invalid/expired/revoked/[dD]isabled)
      carp "Skipping key invalidated by '$1'-flag: ($line)" if $verbose or $debug;
      next;
    }

    #-- a further 'pub' marks a new paragraph or the end of the current paragraph
    #-- a 'FLUSH' marks the end of the the whole text
    if ( $tag eq 'pub'  or  $tag eq 'FLUSH' ) {

      #-- flush intermediate or final results
      if ( @ids  and  @emails ) {

        @emails = List::MoreUtils::uniq @emails; #-- uniq preserves order

        for ( @emails ) {
          #-- $key_mail is quoted C-style (e.g. \x3a is a colon)
          s/\\x(..)/chr(hex($1))/eg;

          #-- tell Perl that this variable is utf8 encoded
          #-- (if Perl version is 5.8.0 or greater)
          eval { $_ = Encode::decode("utf-8", $_, Encode::FB_CROAK) }
            if $] >= 5.008;
        }

        @ids = List::MoreUtils::uniq @ids;
        if ( !$self->get_use_long_key_ids ) {
          $_ = substr($_,-8)  for ( @ids );
        }

        #-- finally, fill result array with all combinations of key-ids and emails (legacy), found in the previous paragraph
        for my $id ( @ids ) {

          if ( $coerce ) {
            push @result, $id, [ @emails ]; #-- "modern" interface
          }
          else {
            for my $m ( @emails ) {
              push @result, ($id, $m); #-- legacy
            }
          }
        }

      } elsif ( @ids  or  @emails ) {
        carp "Incomplete key data - key is probably invalid?  (@ids) x (@emails)!";
      }

      @ids    = ();
      @emails = ();
      last if $fields[1] eq 'FLUSH';


      #-- parse 'new' format (pub:..;  next: uid:..., uid:..., sub:... )
      if ( $fields[9] =~ /^\s*$/ ) {
        $gpg2_mode = 1;
        push @ids, $fields[4];
      }
      #-- parse 'old' format (pub:)
      elsif ( $fields[9] =~ /<[^>]+>/ ) {
        $gpg2_mode = 0;
        push @ids, $fields[4];
        push @emails, $fields[9];
      }
      else {
        die "Cannot parse: ($line)";
      }

    } #-- 'pub' & 'FLUSH' handled obove

    #-- handle 'sub' entries  /  extract key-id
    elsif ( $tag eq 'sub'  and  $gpg2_mode  and   $fields[4]) {
      push @ids, $fields[4];
    }

    #-- handle 'uid' entries  /  extract email
    elsif ( $tag eq 'uid'  and  $gpg2_mode  and   $fields[9] =~ /<[^>]+>/ ) {
      push @emails, $fields[9];
    }

    #-- ignore anything else
    else {
      warn "Ignoring line [gpg2_mode=$gpg2_mode] --  '$line'"  if $debug;
    }

  } #-- loop over output_stdout

  warn  Data::Dumper->Dump( [ \@result], [qw(RESULT_AS_REF)] ) if $debug;

  return @result;
}


sub query_keyring {
    my $self     = shift;
    my %par      = @_;
    my ($search, $debug) = @par{'search','debug'};

    #-- ignore any PIPE signals, in case of gpg exited
    #-- early before we fed our data into it.
    local $SIG{PIPE} = 'IGNORE';

    #-- we parse gpg's output and rely on english
    local $ENV{LC_ALL} = "C";

    #-- get a GnuPG::Interface
    my $gpg = $self->new_gpg_interface;

    #-- initialize Handles
    my $stdout  = IO::Handle->new;
    my $stderr  = IO::Handle->new;
    my $handles = GnuPG::Handles->new(
        stdout => $stdout,
        stderr => $stderr,
    );

    #-- execute gpg --list-public-keys
    my $pid = $gpg->wrap_call(
        handles      => $handles,
        commands     => [ "--list-keys", "--with-colons" ],
        command_args => [$search],
    );

    #-- fetch gpg's STDERR
    my $output_stderr;
    $output_stderr .= $_ while <$stderr>;
    close $stderr;

    #-- fetch gpg's STDOUT
    my $output_stdout;
    $output_stdout .= $_ while <$stdout>;
    close $stdout;

    #-- wait on gpg exit
    waitpid $pid, 0;

    if ( $debug ) {
      warn "LIST_KEYS(CMD)    -- --list-keys --with-colons $search\n";
      warn "LIST_KEYS(STDERR) -- search for ($search):\n$output_stderr\n";
      warn "LIST_KEYS(STDOUT) -- search for ($search):\n$output_stdout\n";
    }

    my @result = $self->_parse_key_list( $output_stdout , %par);

    #-- return result: undef if nothing found, first key-id if
    #-- a scalar is requested, all entries suitable for a hash
    #-- slurp if an array is requested

    # Compatibility note: The first id is always the id of the 'pub' entry, even for a subkey-hit.
    #                     gpgv2: The result should not be used to initialise a hash, since some emails will be clobbered.
    #                     We need another interface here. Curently Mail::GPG uses only the first entry...
    return            if not @result;
    return $result[0] if not wantarray;
    return @result;
}

sub build_rfc3156_multipart_entity {
    my $self = shift;
    my %par  = @_;
    my ($entity, $method) = @par{'entity','method'};

    #-- check, if content-transfer-encoding follows the
    #-- RFC 3156 requirement of being 7bit safe
    $self->check_7bit_encoding_of_all_parts( entity => $entity );

    #-- build entity for signed/encrypted version; first make
    #-- a copy of the given entity (deep copy of body
    #-- files isn't necessary, body data isn't modified
    #-- here).
    my $rfc_entity = $entity->dup;

    #-- determine the part, which is to be signed/encrypted
    my ( $work_part, $multipart );
    if ( $rfc_entity->parts > 1 ) {

        #-- the entity is multipart, so we need to build
        #-- a new version of it with all parts, but without
        #-- the rfc822 mail headers of the original entity
        #-- (according RFC 3156 the signed/encrypted parts
        #--  need MIME content headers only)
        $work_part = MIME::Entity->build( Type => "multipart/mixed" );
        $work_part->add_part($_) for $rfc_entity->parts;
        $rfc_entity->parts( [] );
        $multipart = 1;
    }
    else {

        #-- the entity is single part, so just make it
        #-- multipart and take the first (and only) part
        $rfc_entity->make_multipart;
        $work_part = $rfc_entity->parts(0);
        $multipart = 0;
    }

    #-- configure headers and add first part to the entity
    if ( $method eq 'sign' ) {

        #-- set correct MIME OpenPGP header für multipart/signed
        $rfc_entity->head->mime_attr( "Content-Type", "multipart/signed" );
        $rfc_entity->head->mime_attr( "Content-Type.protocol",
            "application/pgp-signature" );
        $rfc_entity->head->mime_attr( "Content-Type.micalg",
            "pgp-" . lc( $self->get_digest ) );

        #-- add content part as first part
        $rfc_entity->add_part($work_part) if $multipart;
    }
    else {

        #-- set correct MIME OpenPGP header für multipart/encrypted
        $rfc_entity->head->mime_attr( "Content-Type", "multipart/encrypted" );
        $rfc_entity->head->mime_attr( "Content-Type.protocol",
            "application/pgp-encrypted" );

        #-- remove all parts
        $rfc_entity->parts( [] );

        #-- and add OpenPGP version part as first part
        $rfc_entity->attach(
            Type        => "application/pgp-encrypted",
            Disposition => "inline",
            Data        => ["Version: 1\n"],
            Encoding    => "7bit",
        );
    }

    #-- return the newly created entitiy and the part to work on
    return ( $rfc_entity, $work_part );
}

sub mime_sign {
    my $self = shift;
    my %par  = @_;
    my  ($key_id, $passphrase, $entity) =
    @par{'key_id','passphrase','entity'};

    #-- ignore any PIPE signals, in case of gpg exited
    #-- early before we fed our data into it.
    local $SIG{PIPE} = 'IGNORE';

    #-- we parse gpg's output and rely on english
    local $ENV{LC_ALL} = "C";

    #-- get default key ID and passphrase, if not given
    $key_id     = $self->get_default_key_id     if not defined $key_id;
    $passphrase = $self->get_default_passphrase if not defined $passphrase;

    #-- check parameters
    die "No key_id set"     if $key_id     eq '';
    die "No passphrase set" if not defined $passphrase;

    #-- build entity for signed version
    #-- (only the 2nd part with the signature data
    #--  needs to be added later)
    my ( $signed_entity, $sign_part ) = $self->build_rfc3156_multipart_entity(
        entity => $entity,
        method => "sign",
    );

    #-- get a GnuPG::Interface
    my $gpg = $self->new_gpg_interface(
        options => {
            armor       => 1,
            default_key => $key_id,
        },
        passphrase => $passphrase,
    );

    #-- initialize handles
    my $stdin   = IO::Handle->new;
    my $stdout  = IO::Handle->new;
    my $stderr  = IO::Handle->new;
    my $handles = GnuPG::Handles->new(
        stdin  => $stdin,
        stdout => $stdout,
        stderr => $stderr,
    );

    #-- execute gpg for signing
    my $pid = $gpg->detach_sign( handles => $handles );

    #-- put encoded entity data into temporary file
    #-- (faster than in-memory operation)
    my ( $data_fh, $data_file ) = File::Temp::tempfile();
    unlink $data_file;
    $sign_part->print($data_fh);

    #-- perform I/O (multiplexed to prevent blocking)
    my ( $output_stdout, $output_stderr ) = ("", "");
    $self->perform_multiplexed_gpg_io(
        data_fh       => $data_fh,
        data_canonify => 1,
        stdin_fh      => $stdin,
        stderr_fh     => $stderr,
        stdout_fh     => $stdout,
        stderr_sref   => \$output_stderr,
        stdout_sref   => \$output_stdout,
    );

    #-- close reader filehandles (stdin was closed
    #-- by perform_multiplexed_gpg_io())
    close $stdout;
    close $stderr;

    #-- fetch zombie
    waitpid $pid, 0;
    die $output_stderr if $?;

    #-- attach OpenPGP signature as second part
    $signed_entity->attach(
        Type        => "application/pgp-signature",
        Disposition => "inline",
        Data        => [$output_stdout],
        Encoding    => "7bit",
    );

    #-- debugging: create file with signed data
    if ( $self->get_debug ) {
        $self->save_debug_file(
            name    => "mime-sign-data.txt",
            data_fh => $data_fh,
        );
        $self->save_debug_file(
            name => "mime-sign-entity.txt",
            data => \$signed_entity->as_string,
        );
    }

    #-- close temporary data filehandle
    close $data_fh;

    #-- return signed entity
    return $signed_entity;
}

sub mime_encrypt {
    my $self = shift;
    my %par  = @_;
    my ($entity, $recipients) = @par{'entity','recipients'};

    #-- call mime_sign_encrypt() with no_sign option
    return $self->mime_sign_encrypt(
        entity     => $entity,
        recipients => $recipients,
        _no_sign   => 1,
    );
}

sub mime_sign_encrypt {
    my $self = shift;
    my %par = @_;
    my  ($key_id, $passphrase, $entity, $recipients, $_no_sign) =
    @par{'key_id','passphrase','entity','recipients','_no_sign'};

    #-- ignore any PIPE signals, in case of gpg exited
    #-- early before we fed our data into it.
    local $SIG{PIPE} = 'IGNORE';

    #-- we parse gpg's output and rely on english
    local $ENV{LC_ALL} = "C";

    #-- get default key ID and passphrase, if not given
    $key_id     = $self->get_default_key_id     if not defined $key_id;
    $passphrase = $self->get_default_passphrase if not defined $passphrase;

    #-- check parameters
    die "No key_id set"     if not $_no_sign and $key_id     eq '';
    die "No passphrase set" if not $_no_sign and not defined $passphrase;

    #-- build entity for encrypted version
    #-- (only the 2nd part with the encrypted data
    #--  needs to be added later)
    my ( $encrypted_entity, $encrypt_part )
        = $self->build_rfc3156_multipart_entity(
        entity => $entity,
        method => "encrypt",
        );

    #-- get a GnuPG::Interface
    my $gpg = $self->new_gpg_interface(
        options => {
            armor       => 1,
            default_key => $key_id,
        },
        passphrase => $passphrase,
    );

    #-- add recipients, but first extract the mail-adress
    #-- part, otherwise gpg couldn't find keys for adresses
    #-- with quoted printable encodings in the name part-
    $recipients = $self->extract_mail_address( recipients => $recipients, );
    $gpg->options->push_recipients($_) for @{$recipients};

    #-- add default key to recipients if requested
    $gpg->options->push_recipients( $self->get_default_key_id )
        if $self->get_default_key_encrypt
        and $self->get_default_key_id;

    #-- initialize handles
    my $stdin   = IO::Handle->new;
    my $stdout  = IO::Handle->new;
    my $stderr  = IO::Handle->new;
    my $handles = GnuPG::Handles->new(
        stdin  => $stdin,
        stdout => $stdout,
        stderr => $stderr,
    );

    #-- execute gpg for encryption
    my $pid;
    if ($_no_sign) {
        $pid = $gpg->encrypt( handles => $handles );
    }
    else {
        $pid = $gpg->sign_and_encrypt( handles => $handles );
    }

    #-- put encoded entity data into temporary file
    #-- (faster than in-memory operation)
    my ( $data_fh, $data_file ) = File::Temp::tempfile();
    unlink $data_file;
    $encrypt_part->print($data_fh);

    #-- perform I/O (multiplexed to prevent blocking)
    my ( $output_stdout, $output_stderr ) = ("", "");
    $self->perform_multiplexed_gpg_io(
        data_fh       => $data_fh,
        data_canonify => 1,
        stdin_fh      => $stdin,
        stderr_fh     => $stderr,
        stdout_fh     => $stdout,
        stderr_sref   => \$output_stderr,
        stdout_sref   => \$output_stdout,
    );

    #-- close reader filehandles (stdin was closed
    #-- by perform_multiplexed_gpg_io())
    close $stdout;
    close $stderr;

    #-- fetch zombie
    waitpid $pid, 0;
    die $output_stderr if $?;

    #-- attach second part with the encrytped text
    $encrypted_entity->attach(
        Type        => "application/octet-stream",
        Disposition => "inline",
        Data        => [$output_stdout],
        Encoding    => "7bit",
    );

    #-- debugging: create file with encrypted data
    if ( $self->get_debug ) {
        $self->save_debug_file(
            name    => "mime-enc-data.txt",
            data_fh => $data_fh,
        );
        $self->save_debug_file(
            name => "mime-enc-entity.txt",
            data => \$encrypted_entity->as_string,
        );
    }

    #-- close temporary data filehandle
    close $data_fh;

    #-- return encrytped entity
    return $encrypted_entity;
}

sub armor_sign {
    my $self = shift;
    my %par  = @_;
    my  ($key_id, $passphrase, $entity) =
    @par{'key_id','passphrase','entity'};

    #-- ignore any PIPE signals, in case of gpg exited
    #-- early before we fed our data into it.
    local $SIG{PIPE} = 'IGNORE';

    #-- we parse gpg's output and rely on english
    local $ENV{LC_ALL} = "C";

    #-- get default key ID and passphrase, if not given
    $key_id     = $self->get_default_key_id     if not defined $key_id;
    $passphrase = $self->get_default_passphrase if not defined $passphrase;

    #-- check parameters
    die "No key_id set"     if $key_id     eq '';
    die "No passphrase set" if not defined $passphrase;
    die "Entity has no body" if not $entity->bodyhandle;

    #-- check, if body content-transfer-encoding is 7bit safe
    if ( not $self->get_no_strict_7bit_encoding ) {
        my $encoding = $entity->head->get("content-transfer-encoding");
        die "Content transfer encoding '$encoding' is not 7bit safe"
            unless $encoding =~ /^(quoted-printable|base64|7bit)\s*$/i;
    }

    #-- get a GnuPG::Interface, with ASCII armor enabled
    my $gpg = $self->new_gpg_interface(
        options => {
            armor       => 1,
            default_key => $key_id,
        },
        passphrase => $passphrase,
    );

    #-- initialize handles
    my $stdin   = IO::Handle->new;
    my $stdout  = IO::Handle->new;
    my $stderr  = IO::Handle->new;
    my $handles = GnuPG::Handles->new(
        stdin  => $stdin,
        stdout => $stdout,
        stderr => $stderr,
    );

    #-- execute gpg for signing
    my $pid = $gpg->clearsign( handles => $handles );

    #-- put encoded entity data into temporary file
    #-- (faster than in-memory operation)
    my ( $data_fh, $data_file ) = File::Temp::tempfile();
    unlink $data_file;
    $entity->print($data_fh);

    #-- perform I/O (multiplexed to prevent blocking)
    my ( $output_stdout, $output_stderr ) = ("", "");
    $self->perform_multiplexed_gpg_io(
        data_fh       => $data_fh,
        data_canonify => 1,
        stdin_fh      => $stdin,
        stderr_fh     => $stderr,
        stdout_fh     => $stdout,
        stderr_sref   => \$output_stderr,
        stdout_sref   => \$output_stdout,
    );

    #-- close reader filehandles (stdin was closed
    #-- by perform_multiplexed_gpg_io())
    close $stdout;
    close $stderr;

    #-- fetch zombie
    waitpid $pid, 0;
    die $output_stderr if $?;

    #-- build entity for encrypted version
    my $signed_entity = MIME::Entity->build( Data => [$output_stdout], );

    #-- copy all header fields from original entity
    foreach my $tag ( $entity->head->tags ) {
        my @values = $entity->head->get($tag);
        for ( my $i = 0; $i < @values; ++$i ) {
            $signed_entity->head->replace( $tag, $values[$i], $i );
        }
    }

    #-- debugging: create file with signed data
    if ( $self->get_debug ) {
        $self->save_debug_file(
            name => "armor-sign-data.txt",
            data => \$entity->bodyhandle->as_string,
        );
        $self->save_debug_file(
            name => "armor-sign-entity.txt",
            data => \$signed_entity->as_string,
        );
    }

    #-- return the signed entity
    return $signed_entity;
}

sub armor_encrypt {
    my $self = shift;
    my %par  = @_;
    my ($entity, $recipients) = @par{'entity','recipients'};

    #-- call armor_sign_encrypt() with no_sign option
    return $self->armor_sign_encrypt(
        entity     => $entity,
        recipients => $recipients,
        _no_sign   => 1,
    );
}

sub armor_sign_encrypt {
    my $self = shift;
    my %par = @_;
    my  ($key_id, $passphrase, $entity, $recipients, $_no_sign) =
    @par{'key_id','passphrase','entity','recipients','_no_sign'};

    #-- ignore any PIPE signals, in case of gpg exited
    #-- early before we fed our data into it.
    local $SIG{PIPE} = 'IGNORE';

    #-- we parse gpg's output and rely on english
    local $ENV{LC_ALL} = "C";

    #-- get default key ID and passphrase, if not given
    if ( not $_no_sign ) {
        $key_id = $self->get_default_key_id if not defined $key_id;
        $passphrase = $self->get_default_passphrase
            if not defined $passphrase;

        #-- check parameters
        die "No key_id set"     if $key_id     eq '';
        die "No passphrase set" if not defined $passphrase;
    }

    #-- check parameters
    die "Entity has no body" if not $entity->bodyhandle;

    #-- get a GnuPG::Interface, with ASCII armor enabled
    my $gpg = $self->new_gpg_interface(
        options => {
            armor       => 1,
            default_key => $key_id,
        },
        passphrase => $passphrase,
    );

    #-- add recipients, but first extract the mail-adress
    #-- part, otherwise gpg couldn't find keys for adresses
    #-- with quoted printable encodings in the name part-
    $recipients = $self->extract_mail_address( recipients => $recipients, );
    $gpg->options->push_recipients($_) for @{$recipients};

    #-- add default key to recipients if requested
    $gpg->options->push_recipients( $self->get_default_key_id )
        if $self->get_default_key_encrypt
        and $self->get_default_key_id;

    #-- initialize handles
    my $stdin   = IO::Handle->new;
    my $stdout  = IO::Handle->new;
    my $stderr  = IO::Handle->new;
    my $handles = GnuPG::Handles->new(
        stdin  => $stdin,
        stdout => $stdout,
        stderr => $stderr,
    );

    #-- execute gpg for encryption
    my $pid;
    if ($_no_sign) {
        $pid = $gpg->encrypt( handles => $handles );
    }
    else {
        $pid = $gpg->sign_and_encrypt( handles => $handles );
    }

    #-- put encoded entity data into temporary file
    #-- (faster than in-memory operation)
    my ( $data_fh, $data_file ) = File::Temp::tempfile();
    unlink $data_file;
    $entity->print($data_fh);

    #-- perform I/O (multiplexed to prevent blocking)
    my ( $output_stdout, $output_stderr ) = ("", "");
    $self->perform_multiplexed_gpg_io(
        data_fh       => $data_fh,
        data_canonify => 0,
        stdin_fh      => $stdin,
        stderr_fh     => $stderr,
        stdout_fh     => $stdout,
        stderr_sref   => \$output_stderr,
        stdout_sref   => \$output_stdout,
    );

    #-- close reader filehandles (stdin was closed
    #-- by perform_multiplexed_gpg_io())
    close $stdout;
    close $stderr;

    #-- fetch zombie
    waitpid $pid, 0;
    die $output_stderr if $?;

    #-- build entity for encrypted version
    my $encrypted_entity = MIME::Entity->build(
        Type     => "text/plain",
        Encoding => "7bit",
        Data     => [$output_stdout],
    );

    #-- copy header fields from original entity
    foreach my $tag ( $entity->head->tags ) {
        next if $tag =~ /^content/i;
        my @values = $entity->head->get($tag);
        for ( my $i = 0; $i < @values; ++$i ) {
            $encrypted_entity->head->replace( $tag, $values[$i], $i );
        }
    }

    #-- debugging: create file with signed data
    if ( $self->get_debug ) {
        $self->save_debug_file(
            name => "armor-enc-data.txt",
            data => \$entity->bodyhandle->as_string,
        );
        $self->save_debug_file(
            name => "armor-enc-entity.txt",
            data => \$encrypted_entity->as_string,
        );
    }

    #-- return the signed entity
    return $encrypted_entity;
}

sub decrypt {
    my $self = shift;
    my %par  = @_;
    my ($entity, $passphrase) = @par{'entity','passphrase'};

    #-- ignore any PIPE signals, in case of gpg exited
    #-- early before we fed our data into it.
    local $SIG{PIPE} = 'IGNORE';

    #-- we parse gpg's output and rely on english
    local $ENV{LC_ALL} = "C";

    #-- get default passphrase, if not given
    $passphrase = $self->get_default_passphrase if not defined $passphrase;

    #-- check if the entity is encrypted at all
    #-- (dies if not)
    my $encrypted_text;
    my $is_armor = $self->check_encryption(
        entity              => $entity,
        encrypted_text_sref => \$encrypted_text,
    );

    #-- get a GnuPG::Interface
    my $gpg = $self->new_gpg_interface( passphrase => $passphrase, );

    #-- initialize handles
    my $stdin  = IO::Handle->new;
    my $stdout = IO::Handle->new;
    my $stderr = IO::Handle->new;
    my $status = IO::Handle->new;

    my $handles = GnuPG::Handles->new(
        stdin  => $stdin,
        stdout => $stdout,
        stderr => $stderr,
        status => $status,
    );

    #-- start gpg for decryption
    my $pid = $gpg->decrypt( handles => $handles );

    #-- put encoded entity data into temporary file
    #-- (faster than in-memory operation)
    my ( $data_fh, $data_file ) = File::Temp::tempfile();
    unlink $data_file;
    print $data_fh $encrypted_text;

    #-- perform I/O (multiplexed to prevent blocking)
    my ( $output_stdout, $output_stderr, $output_status ) = ( "", "", "" );

    $self->perform_multiplexed_gpg_io(
        data_fh       => $data_fh,
        data_canonify => 1,
        stdin_fh      => $stdin,
        stderr_fh     => $stderr,
        stdout_fh     => $stdout,
        status_fh     => $status,
        stderr_sref   => \$output_stderr,
        stdout_sref   => \$output_stdout,
        status_sref   => \$output_status,
    );

    #-- close reader filehandles (stdin was closed
    #-- by perform_multiplexed_gpg_io())
    close $stdout;
    close $stderr;

    #-- fetch zombie
    waitpid $pid, 0;
    my $rc = $? >> 8;

    #-- don't die here for return values != 0, because
    #-- this also happens for encrypted+signed mails,
    #-- where the public key is missing for verification
    #-- and that's not intended here.

    #-- parse decrypted text
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);

    # for armor message (which usually contain no MIME entity)
    # and if the first line seems to be no header, add an empty
    # line at the top, otherwise the first line of a text message
    # will be removed by the parser.
    if ( $is_armor and $output_stdout !~ /^[\w-]+:/ ) {
        $output_stdout = "\n" . $output_stdout;
    }

    my $dec_entity = $parser->parse_data( $output_stdout );

    #-- Add headers from original entity
    if ( $dec_entity->head->as_string eq '' ) {
        $dec_entity->head( $entity->head->dup );
    }
    else {

        #-- copy header fields from original entity
        foreach my $tag ( $entity->head->tags ) {
            next if $tag =~ /^content/i;
            my @values = $entity->head->get($tag);
            for ( my $i = 0; $i < @values; ++$i ) {
                $dec_entity->head->replace( $tag, $values[$i], $i );
            }
        }
    }

    #-- debugging: create file with encrypted data
    if ( $self->get_debug ) {
        $self->save_debug_file(
            name => "dec-data.txt",
            data => $dec_entity->as_string,
        );
    }

    #-- fetch information from gpg's stderr output
    #-- and construct a Mail::GPG::Result object from it
    my $result = Mail::GPG::Result->new(
        mail_gpg   => $self,
        gpg_stdout => \$output_stdout,
        gpg_stderr => \$output_stderr,
        gpg_status => \$output_status,
        gpg_rc     => $rc,
    );

    #-- return decrypted entity and result object
    return $dec_entity if not wantarray;
    return ( $dec_entity, $result );
}

sub verify {
    my $self     = shift;
    my %par      = @_;
    my ($entity) = $par{'entity'};

    #-- ignore any PIPE signals, in case of gpg exited
    #-- early before we fed our data into it.
    local $SIG{PIPE} = 'IGNORE';

    #-- we parse gpg's output and rely on english
    local $ENV{LC_ALL} = "C";

    #-- check if the entity is signed
    my ( $signed_text, $signature_text );

    if ( $entity->effective_type =~ m!multipart/signed!i ) {

        #-- is this a valid RFC 3156 multipart/signed entity?
        die "Entity must have two parts"
            if $entity->parts != 2;
        die "Entity is not OpenPGP signed"
            unless $entity->parts(1)->effective_type
            =~ m!application/pgp-signature!i;

        #-- hopefully the $entity was parsed with
        #-- decode_bodies(0), otherwise this would
        #-- return decoded data, but the signature
        #-- is calculated on the *encoded* version.
        $signed_text    = $entity->parts(0)->as_string;
        $signature_text = $entity->parts(1)->body_as_string;

    }
    elsif ( $entity->bodyhandle ) {

        #-- probably an ASCII armor signed entity
        #-- in that case we need the *decoded* data
        $signed_text = $entity->bodyhandle->as_string;
        die "Entity is not OpenPGP signed"
            unless $signed_text =~ /^-----BEGIN PGP SIGNED MESSAGE-----/m;
    }
    else {
        die "Entity is not multipart/signed and has no body";
    }

    #-- get a GnuPG::Interface
    my $gpg = $self->new_gpg_interface;

    #-- initialize handles
    my $stdin  = IO::Handle->new;
    my $stdout = IO::Handle->new;
    my $stderr = IO::Handle->new;
    my $status = IO::Handle->new;

    my $handles = GnuPG::Handles->new(
        stdin  => $stdin,
        stdout => $stdout,
        stderr => $stderr,
        status => $status,
    );

    #-- distinguish between ascii amor embedded signature
    #-- and detached signature (RFC 3156)
    my ( $pid, $sign_file, $sign_fh );
    if ($signature_text) {

        #-- signature is detached, save it to a temp file
        ( $sign_fh, $sign_file ) = File::Temp::tempfile();
        print $sign_fh $signature_text;
        close $sign_fh;

        #-- pass signature filename to gpg
        $pid = $gpg->verify(
            handles      => $handles,
            command_args => [ $sign_file, "-" ],
        );

    }
    else {

        #-- ASCII armor message with embedded signature
        $pid = $gpg->verify( handles => $handles, );
    }

    #-- put encoded entity data into temporary file
    #-- (faster than in-memory operation)
    my ( $data_fh, $data_file ) = File::Temp::tempfile();
    unlink $data_file;
    print $data_fh $signed_text;

    #-- perform I/O (multiplexed to prevent blocking)
    my ( $output_stdout, $output_stderr, $output_status ) = ( "", "", "" );
    $self->perform_multiplexed_gpg_io(
        data_fh       => $data_fh,
        data_canonify => 1,
        stdin_fh      => $stdin,
        stderr_fh     => $stderr,
        stdout_fh     => $stdout,
        status_fh     => $status,
        stderr_sref   => \$output_stderr,
        stdout_sref   => \$output_stdout,
        status_sref   => \$output_status,
    );

    #-- close reader filehandles (stdin was closed
    #-- by perform_multiplexed_gpg_io())
    close $stdout;
    close $stderr;

    #-- fetch zombie
    waitpid $pid, 0;
    my $rc = $? >> 8;

    #-- remove detached signature file
    unlink $sign_file if defined $sign_file;

    #-- debugging: create file with verified data
    if ( $self->get_debug ) {
        $self->save_debug_file(
            name => "verify-data.txt",
            data => \$signed_text,
        );
    }

    #-- construct a Mail::GPG::Result object from
    #-- gpg's stderr output
    my $result = Mail::GPG::Result->new(
        mail_gpg   => $self,
        gpg_stdout => \$output_stdout,
        gpg_stderr => \$output_stderr,
        gpg_status => \$output_status,
        gpg_rc     => $rc,
    );

    #-- return result object
    return $result;
}

sub is_encrypted {
    my $self     = shift;
    my %par      = @_;
    my ($entity) = $par{'entity'};

    if ( $entity->effective_type =~ m!multipart/encrypted!i ) {

        #-- is this a valid RFC 3156 multipart/encrypted entity?
        return 0 if $entity->parts != 2;
        return 0
            unless $entity->parts(0)->effective_type
            =~ m!application/pgp-encrypted!i;

    }
    elsif ( $entity->bodyhandle ) {

        #-- probably an ASCII armor encrypted entity
        #-- check the decoded body for a PGP message
        return 0
            unless $entity->bodyhandle->as_string
            =~ /^-----BEGIN PGP MESSAGE-----/m;
    }
    else {
        return 0;
    }

    return 1;
}

sub is_signed {
    my $self     = shift;
    my %par      = @_;
    my ($entity) = $par{'entity'};

    if ( $entity->effective_type =~ m!multipart/signed!i ) {

        #-- is this a valid RFC 3156 multipart/signed entity?
        return 0 if $entity->parts != 2;
        return 0
            unless $entity->parts(1)->effective_type
            =~ m!application/pgp-signature!i;

    }
    elsif ( $entity->bodyhandle ) {

        #-- probably an ASCII armor signed entity,
        #-- check the decoded body for a PGP message
        return 0
            unless $entity->bodyhandle->as_string
            =~ /^-----BEGIN PGP SIGNED MESSAGE-----/m;
    }
    else {
        return 0;
    }

    return 1;
}

sub is_signed_quick {
    my $self = shift;
    my %par  = @_;
    my ($mail_fh, $mail_sref) = @par{'mail_fh', 'mail_sref'};

    croak "Specify mail_fh xor mail_sref"
        unless $mail_fh xor $mail_sref;

    if ( defined $mail_fh ) {

        #-- rewind filehandle
        seek( $mail_fh, 0, 0 );

        #-- read filehandle and do rough checks
        local ($_);
        my $is_signed = 0;
        while (<$mail_fh>) {
            if (m!application/pgp-signature!i) {
                $is_signed = 1;
                last;
            }
            if (/^-----BEGIN PGP SIGNED MESSAGE-----/) {
                $is_signed = 1;
                last;
            }
        }

        #-- rewind filehandle again
        seek( $mail_fh, 0, 0 );

        #-- return sign status
        return $is_signed;

    }
    elsif ( defined $mail_sref ) {

        #-- looks like a RFC 3156 multipart/signed entity?
        return 1 if $$mail_sref =~ m!application/pgp-signature!i;

        #-- or ASCII armor signed?
        return 1 if $$mail_sref =~ m!^-----BEGIN PGP SIGNED MESSAGE-----!m;

        #-- not signed at all
        return 0,;
    }

    return 1;
}

sub get_decrypt_key {
    my $self     = shift;
    my %par      = @_;
    my ($entity) = $par{'entity'};

    #-- ignore any PIPE signals, in case of gpg exited
    #-- early before we fed our data into it.
    local $SIG{PIPE} = 'IGNORE';

    #-- we parse gpg's output and rely on english
    local $ENV{LC_ALL} = "C";

    #-- check if the entity is encrypted at all
    #-- (dies if not)
    my $encrypted_text;
    my $is_armor = $self->check_encryption(
        entity              => $entity,
        encrypted_text_sref => \$encrypted_text,
    );

    #-- get a GnuPG::Interface
    my $gpg = $self->new_gpg_interface;

    #-- initialize handles
    my $stdin   = IO::Handle->new;
    my $stdout  = IO::Handle->new;
    my $stderr  = IO::Handle->new;
    my $handles = GnuPG::Handles->new(
        stdin  => $stdin,
        stdout => $stdout,
        stderr => $stderr,
    );

    #-- start gpg for decryption
    my $pid = $gpg->wrap_call(
        handles  => $handles,
        commands =>
            [ "--decrypt", "--batch", "--list-only", "--status-fd", "1" ],
    );

    #-- put encoded entity data into temporary file
    #-- (faster than in-memory operation)
    my ( $data_fh, $data_file ) = File::Temp::tempfile();
    unlink $data_file;
    print $data_fh $encrypted_text;

    #-- perform I/O (multiplexed to prevent blocking)
    my ( $output_stdout, $output_stderr ) = ( "", "" );
    $self->perform_multiplexed_gpg_io(
        data_fh       => $data_fh,
        data_canonify => 1,
        stdin_fh      => $stdin,
        stderr_fh     => $stderr,
        stdout_fh     => $stdout,
        stderr_sref   => \$output_stderr,
        stdout_sref   => \$output_stdout,
    );

    #-- close reader filehandles (stdin was closed
    #-- by perform_multiplexed_gpg_io())
    close $stdout;
    close $stderr;

    #-- fetch zombie
    waitpid $pid, 0;
    my $rc = $? >> 8;

    #-- grep ENC_TO and NO_SECKEY items
    my ( @enc_to_keys, %no_sec_keys, $line );
    while ( $output_stdout =~ /^(.*)$/mg ) {
        $line = $1;
        push @enc_to_keys, $1 if $line =~ /ENC_TO\s+([^\s]+)/;
        $no_sec_keys{$1} = 1 if $line =~ /NO_SECKEY\s+([^\s]+)/;
    }

    #-- find first key we have the secret portion of
    my $key_id;
    foreach my $k (@enc_to_keys) {
        if ( not exists $no_sec_keys{$k} ) {
            $key_id = $k;
            last;
        }
    }

    #-- get mail address of this key
    my $key_mail;
    ( $key_id, $key_mail ) = $self->query_keyring( search => $key_id );

    return $key_id if not wantarray;
    return ( $key_id, $key_mail );
}

sub extract_mail_address {
    my $self         = shift;
    my %par          = @_;
    my ($recipients) = $par{'recipients'};

    my @recipients;

    my $address;
    foreach my $r ( @{$recipients} ) {
        ($address) = Mail::Address->parse($r);
        push @recipients, $address
            ? $address->address
            : $r;
    }
    return \@recipients;
}

sub parse {
    my $thing = shift;
    my %par   = @_;
    my ($mail_fh, $mail_sref) = @par{'mail_fh','mail_sref'};

    croak "Specify mail_fh xor mail_sref"
        unless $mail_fh xor $mail_sref;

    require MIME::Parser;
    my ( $parser, $entity );

    #-- First parse without body decoding, which is correct
    #-- for MIME messages
    $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    $parser->decode_bodies(0);
    $entity = $mail_fh
        ? $parser->parse($mail_fh)
        : $parser->parse_data($$mail_sref);

    #-- Ok, if this is a MIME message
    return $entity
        if $entity->effective_type eq 'multipart/signed'
        or $entity->effective_type eq 'multipart/encrypted';

    #-- Now with body decoding, which is MIME::Parser's default
    #-- and correct for OpenPGP armor message. Probably this
    #-- isn't an OpenPGP message at all. But also in that case
    #-- it's the best to return a decoded entity, as MIME::Parser
    #-- usually does.
    seek( $mail_fh, 0, 0 ) if $mail_fh;
    $parser->decode_bodies(1);
    $entity = $mail_fh
        ? $parser->parse($mail_fh)
        : $parser->parse_data($$mail_sref);

    return $entity;
}

sub get_key_trust {
    my $self     = shift;
    my %par      = @_;
    my ($key_id) = $par{'key_id'};

    # Suppress warnings about unknown record type 'tru'
    # in GnuPG::Interface
    local $SIG{__WARN__} = sub {1};

    my $gpg  = $self->new_gpg_interface;
    my @keys = $gpg->get_public_keys($key_id);

    croak "Request for key ID '$key_id' got multiple result"
        if @keys > 1;

    return "" unless $keys[0];
    return $keys[0]->owner_trust;
}

1;

__END__


=head1 NAME

Mail::GPG - Handling of GnuPG encrypted / signed mails

=head1 SYNOPSIS

  use Mail::GPG;

  my $mg = Mail::GPG->new;

  my %keys_id2mail = $mg->query_keyring (
    search => 'joern@zyn.de',
  );

  my $entity = MIME::Entity->build (
    From     => 'joern@zyn.de',
    Subject  => "Mail::GPG Testmail",
    Data     => [ "Hiho, a nice encrypted mail" ],
    Encoding => "quoted-printable",
    Charset  => "iso-8859-1",
  );

  my $encrypted_entity = $mg->mime_sign_encrypt (
    entity     => $entity,
    key_id     => $key_id,
    password   => 'topsecret',
    recipients => [ 'niceguy@zyn.de' ],
  );

  my $mail_text = $encrypted_entity->as_string;

  # and a lot more...

  $mg->mime_sign ( ... );
  $mg->mime_encrypt ( ... );
  $mg->mime_sign_encrypt ( ... );

  $mg->armor_sign ( ... );
  $mg->armor_encrypt ( ... );
  $mg->armor_sign_encrypt ( ... );

  $mg->parse ( ... );

  $mg->decrypt ( ... );
  $mg->verify ( ... );

  $mg->is_encrypted ( ... );
  $mg->is_signed ( ... );
  $mg->is_signed_quick ( ... );

  $mg->get_decrypt_key ( ... );
  $mg->get_key_trust ( ... );

=head1 DESCRIPTION

This Perl modules handles all the details of encrypting and
signing Mails using GnuPG according to RFC 3156 and RFC 2440,
that is OpenPGP MIME and traditional armor signed/encrypted mails.

=head1 PREREQUISITES

  Perl              >= 5.00503
  MIME-tools        >= 5.419
  MIME::QuotedPrint >= 2.20  (part of MIME-Base64 distribution)
  GnuPG::Interface  >= 0.52
  Event             >= 1.24
  List::MoreUtils   >= 0.410

Since version 1.0.7 the Event module is loaded when present. This
gives a small performance boost when handling big entities. If you
like to fallback to the old IO::Select based behaviour set either

  $Mail::GPG::SKIP_EVENT    = 1
  $ENV{MAIL_GPG_SKIP_EVENT} = 1
  
before loading Mail::GPG.

=head1 INSTALLATION

Then install Mail::GPG

  % cd ../Mail-GPG-x.xx
  % perl Makefile.PL
  % make test
  % make install

Mail::GPG has a bunch of tests which will create a temporary
gpg keyring to be able to do real encryption and stuff. You
need to have gpg in your path for the tests to succeed, otherwise
all useful tests will be skipped.

Note that the test 04.big needs some time, on an Athlon 1800XP
about 12 seconds, so be patient ;)

=head1 KNOWN BUGS

Currently none. Please report any bugs to the author: Joern Reder
<joern AT zyn.de>.

=head1 EXAMPLES

The Mail::GPG distribution contains the program mgpg-test:

  Usage: mgpg-test file ...

It takes one or more filenames of mails as
arguments, analyzes them, prints information about
signatures and decrypts encrypteded mails (after asking
for the correspondent passphrases). The script is rather
small and a good example of Mail::GPG usage.

The regression tests in the t/ directory of the
distribution show exemplary usage of all Mail::GPG features.

=head1 CONSTRUCTOR AND ATTRIBUTES

=head2 new

  $mg = Mail::GPG->new (
    attribute => value,
    ...
  );

The B<new> class method returns a new instance of the
Mail::GPG class, initialized with the attributes passed
as hash parameters.

=head2 Attributes

This is the list of attributes you can pass to the
B<new> method and access using the methods B<set>_attribute
and B<get>_attribute:

=over 4

=item B<default_key_id>

The B<default_key_id> takes a GnuPG key id. It is used for
all methods which expect a key id, if you don't pass a
specific key id to them.

=item B<default_passphrase>

You can store the passphrase of the B<default_key_id> using
this attribute. All methods expecting the passphrase will
take it from here by default.

B<WARNING>

Aware that storing the secret key password in many variables
in your program increases the risk of being attacked by
memory inspection. So you probably don't want to use the
B<default_passphrase> attribute.

=item B<debug>

Setting the B<debug> attribute to a true value will cause
Mail::GPG to dump files into the B<debug_dir> (see beyond).
This way you can track entities, if signature validation
or decryption fails for some reason.

=item B<debug_dir>

This defaults to File::Spec->tmpdir. The directory is used
to store debug files (see B<debug> above).

=item B<gnupg_hash_init>

This attribute corresponds to the GnuPG::Interface hash_init
attribute. Please refer to the GnuPG::Interface manpage for
details. E.g. you can set gpg's --homedir option this way
and much more.

=item B<digest>

This is the digest used by GnuPG to calculate hash values
for signatures. By default Mail::GPG sets it to "RIPEMD160",
which is needed to handle DSA keys (which are very common).
You can check the supported digests of your gpg installation
by executing 'gpg --version'.

=item B<default_key_encrypt>

Set this attribute to a true value if you whish to have the
B<default_key_id> always added as a recipient for encrypted
mails.

=item B<no_strict_7bit_encoding>

By default this attribute is false, that means that all data
which should be signed or encrypted is firstly checked for
a RFC 3156 conform 7bit encoding. Until you set
B<no_strict_7bit_encoding> to true, an exception will be
raised for non 7bit transparent encodings.

=item B<use_long_key_ids>

Mail::GPG prior version 1.0.4 always used short 32 bit key id's.
By setting this attribute to TRUE you can switch to long
64bit key id's. This affects the query_keyring() method and
the key id's stored in Mail::GPG::Result.

=item B<gpg_call>

This defaults to 'gpg' and is the path of the gpg program
executed through GnuPG::Interface. Change this attribute
if the 'gpg' program is not in your PATH.

=back

=head1 METHODS TO CREATE MIME OpenPGP MESSAGES (RFC 3156)

=head2 mime_sign

  $signed_entity = $mg->mime_sign (
      entity     => $entity,
    [ key_id     => $key_id,
      passphrase => $passphrase ]
  );

This method returns the MIME signed version of an entity.

=over 4

=item entity

The MIME::Entity object to be signed. By default it must
not contain any parts with non 7bit content transfer
encodings, because RFC 3156 forbids that. If you want
to be able to pass 8bit also (and thus create non RFC
conform data), you have to set the B<no_strict_7bit_encoding>
attribute.

=item key_id

The id of the key used to sign the entity. This defaults to
B<default_key_id> if omitted here.

=item passphrase

The corresponding passphrase of the key. This defaults to
B<default_passphrase> if omitted here.

=back

=head2 mime_encrypt

  $encrypted_entity = $mg->mime_encrypt (
      entity     => $entity,
      recipients => \@recipients,
  );

Returns the MIME encrypted version of an entity.

=over 4

=item entity

The MIME::Entity object to be encrypted. By default it must
not contain any parts with non 7bit content transfer
encodings, because RFC 3156 forbids that. If you want
to be able to pass 8bit also (and thus create non RFC
conform data), you have to set the B<no_strict_7bit_encoding>
attribute.

=item recipients

This is a reference to an array of recipients, which may be
email adresses or key id's. If B<default_key_encrypt> is
set, the B<default_key_id> will be added as a recipient
automatically.

=back

=head2 mime_sign_encrypt

  $encrypted_signed_entity = $mg->mime_sign_encrypt (
      entity     => $entity,
      recipients => \@recipients,
    [ key_id     => $key_id,
      passphrase => $passphrase ]
  );

Returns the encrypted and signed version of an entity.

=over 4

=item entity

The MIME::Entity object to be signed and encrypted. By default it must
not contain any parts with non 7bit content transfer
encodings, because RFC 3156 forbids that. If you want
to be able to pass 8bit also (and thus create non RFC
conform data), you have to set the B<no_strict_7bit_encoding>
attribute.

=item recipients

This is a reference to an array of recipients, which may be
email adresses or key id's. If B<default_key_encrypt> is
set, the B<default_key_id> will be added as an recipient
automatically.

=item key_id

The id of the key used to sign the entity. This defaults to
B<default_key_id> if omitted here.

=item passphrase

The corresponding passphrase of the key. This defaults to
B<default_passphrase> if omitted here.

=back

=head1 METHODS TO CREATE ARMOR OpenPGP MESSAGES (RFC 2440)

=head2 armor_sign

  $signed_entity = $mg->armor_sign (
      entity     => $entity,
    [ key_id     => $key_id,
      passphrase => $passphrase ]
  );

This method returns the armor signed version of a MIME::Entity.

=over 4

=item entity

The MIME::Entity object to be signed. It must not have any
parts and a 7bit clean content transfer encoding.

=item key_id

The id of the key used to sign the entity. This defaults to
B<default_key_id> if omitted here.

=item passphrase

The corresponding passphrase of the key. This defaults to
B<default_passphrase> if omitted here.

=back

=head2 armor_encrypt

  $signed_entity = $mg->armor_encrypt (
      entity     => $entity,
      recipients => \@recipients,
  );

Returns the armor encrypted version of an entity.

=over 4

=item entity

The MIME::Entity object to be encrypted. It must not have any
parts and a 7bit clean content transfer encoding.

=item recipients

This is a reference to an array of recipients, which may be
email adresses or key id's. If B<default_key_encrypt> is
set, the B<default_key_id> will be added as an recipient
automatically.

=back

=head2 armor_sign_encrypt

  $signed_entity = $mg->mime_sign_encrypt (
      entity     => $entity,
      recipients => \@recipients,
    [ key_id     => $key_id,
      passphrase => $passphrase ]
  );

Returns the encrypted and signed version of an entity.

=over 4

=item entity

The MIME::Entity object to be encrypted. It must not have any
parts and a 7bit clean content transfer encoding.

=item recipients

This is a reference to an array of recipients, which may be
email adresses or key id's. If B<default_key_encrypt> is
set, the B<default_key_id> will be added as an recipient
automatically.

=item key_id

The id of the key used to sign the entity. This defaults to
B<default_key_id> if omitted here.

=item passphrase

The corresponding passphrase of the key. This defaults to
B<default_passphrase> if omitted here.

=back

=head1 METHODS FOR PARSING, DECRYPTION AND VERIFICATION

=head2 parse

  $entity = Mail::GPG->parse (
      mail_fh   => $filehandle,
    | mail_sref => \$mail_data
  );

This is a convenience method for parsing a mail message. It
uses MIME::Parser and distinguish between MIME and non-MIME messages,
doing the right thing regarding reading decoded or encoded
bodies.

=over 4

=item mail_fh

An opened filehandle of the mail message in question.

=item mail_sref

A reference to a scalar holding the mail message to be parsed.

=back

=head2 Details about parsing with MIME::Parser for Mail::GPG

Parsing is not trivial, because we have a basic problem with
MIME::Parser and MIME::Entity. If the mail in question is
text/plain and contains an ASCII armor PGP message, Mail::GPG
must see the B<decoded> data.

But if it's a MIME PGP message, Mail::GPG needs the
B<encoded> data.

You can advice MIME::Parser to create an encoded entity
(by default it creates decoded entities and encodes them on
demand). You can activate this transparent encoding mode by
setting B<decode_bodies> attribute of MIME::Parser to 0
(it defaults to 1):

  $parser = MIME::Parser->new;
  $parser->decode_bodies(0);

So you need to set decode_bodies(0) for MIME  messages
and keep the default of decode_bodies(1) for armor
messages. But how can you know in advance which is right
without having the entity parsed already? You can't.

So the solution is to parse the entity twice if it's
MIME, and keep the decoded version from the first
parse run otherwise, or you do some quick analysis on the
data in question, without really parsing it.

  $parser = MIME::Parser->new;
  $parser->decode_bodies(0);
  $entity = $parser->parse_data($mail_data);
  if ( $entity->effective_type ne 'multipart/signed' and
       $entity->effective_type ne 'multipart/encrypted' ) {
    $parser->decode_bodies(1);
    $entity = $parser->parse_data($mail_data);
  }

That's exactly what the parse() method does for you, so
it's a good idea to use it instead of fiddling with all
the details yourself ;)

=head2 decrypt

  ($decrypted_entity, $result) = $mg->decrypt (
      entity     => $entity,
    [ passphrase => $passphrase ]
  );

Returns the decrypted version of an entity and a Mail::GPG::Result
object with detailed information about the entities encryption
(refer to the manpage of Mail::GPG::Result).

=over 4

=item entity

The MIME::Entity to be decrypted. Please read the chapter
about the parse() method of details about this entity.

=item passphrase

The corresponding passphrase of the secret key which is needed
to decrypt the message. Use B<get_decrypt_key> to determine the
corresponding key. This defaults to B<default_passphrase>
if omitted here.

=back

=head2 verify

  $result = $mg->verify (
      entity => $entity,
  );

Returns a Mail::GPG::Result object with detailed information
about the signature of an entity. Refer to the manpage of
Mail::GPG::Result.

=over 4

=item entity

The signed MIME::Entity to be verified. Please read the chapter
about the parse() method of details about this entity.

=back

=head1 METHODS FOR ENTITY INSPECTION

=head2 is_signed

  $signed = $mg->is_signed (
      entity => $entity,
  );

Returns whether an entity is signed or not.

=over 4

=item entity

The entity to be checked for a signature.

=back

=head2 is_signed_quick

  $signed = $mg->is_signed_quick (
      mail_fh   => $filehandle,
    | mail_sref => \$mail_data
  );

Does some very quick and rough detection whether a message is signed or not.
Note: the special about this method is it doesn't require a MIME::Entity.
Creating a MIME::Entity is the opposite of being "quick" ;)

Major drawback is, you can't really rely on the result of this method.
It can't detect base64 encoded armor signed messages (it reports always
false on them).

Also it may report a signature although it's not signed at all. E.g. the
message is a reply to a armor signed message and the quoted parts contain the
-----BEGIN PGP SIGNATURE----- string or something like that. To be really
sure you should call is_signed() afterwards.

Just use is_signed_quick() to decide whether you want to do deeper inspection
or not, but don't rely only on its result.

=over 4

=item mail_fh

An opened filehandle of the mail message to be analyzed. Note: the filehandle
is rewinded by the method using seek($mail_fh, 0, 0).

=item mail_sref

A reference to a scalar holding the mail message to be analyzed.

=back

=head2 is_encrypted

  $encrypted = $mg->is_encrypted (
      entity     => $entity,
  );

Return whether an entity is encrypted or not.

=over 4

=item entity

The entity to be checked for a encryption.

=back

=head2 get_decrypt_key

  ($key_id, $key_mail) = $mg->get_decrypt_key (
      entity => $entity,
  );

Returns secret key id and mail address which is needed to
decrypt an encrypted entity.

=over 4

=item entity

The entity to inspect.

=back

=head1 METHODS FOR KEY RING INSPECTION

=head2 query_keyring

  %result              = $mg->query_keyring ( search => $search );
  $key_id              = $mg->query_keyring ( search => $search );
  ($key_id, $key_mail) = $mg->query_keyring ( search => $search );
  %mails_by_key_id     = $mg->query_keyring ( search => $search, coerce => 1 );

Searches the keyring for a key id or email address.
In list context a subsequent list of key id and mail
address pairs (suitable for a hash variable) is returned.
In scalar context the key id of the first entry is returned.
If nothing was found undef is returned.

If you need more detailed control about the query result,
use GnuPG::Interface->get_public_keys and
GnuPG::Interface->get_secret_keys instead. For
details refer to the GnuPG::PrimaryKey manpage.

If you use Perl 5.8.0 or better email addresses will
be returned as an utf8 enabled scalar, because gpg always
lists email adresses in utf8. Since Perl > 5.8.0 handles
utf8 very nice and transparently, you mostly don't need
to care about this ;)

If you use the module with older Perl versions you need
to handle utf8 encoded data yourself.

=head3 coerce option & GPGv2

When using GPGv2, the current implementation tries to
simulate the former behaviour. The first entry will be
the PK-ID (pub: not sub:). The second entry will be the first
valid (i.e. not expired, not revoked, etc.) email entry.

If there are sub-keys (sub:) or more email entries (uid:), all
combinations are returned and the user needs to further filter the
result. Since there may be many emails assigned to a given key-id,
assigning to a hash will probably clobber previous id/email entries.

In order to allow assignment to a hash again, the parameter
C<coerce =E<gt> 1> can be used. When active, a list of pairs is
returned where the first item is the key-id and the
second item is an array-ref to a list of email addresses.

 %result = $mg->query_keyring ( search => $search, coerce => 1 );
 # (
 #   '999F00DAE20F5123',  [ 'Valid Test Key   <userX@localdomain>',
 #                          'Valid Test Key   <new@localdomain>' ],
 #   'CAFE333F196ED333',  [ 'Valid Test Key   <userX@localdomain>',
 #                          'Valid Test Key   <new@localdomain>' ]
 # )

=over 4

=item search

Key id or email address to query for.

=item coerce

When true, returns all emails belonging to a key as an array-reference.
(patched version only!)

=back


Tests: All temporary files are created in directory F</tmp/mail-gpg-test> now.
The environment variable C<DUMPDIR> can be used to select an alternative directory.



=head2 get_key_trust

  $trust = $mg->get_key_trust (
    key_id => $key_id
  );
  
Reports the trust level of the given key. The known levels are listed in
the DETAILS file of the gnupg distribution, but qouted here for convenience
(gnupg 1.2.5):

  o = Unknown (this key is new to the system)
  i = The key is invalid (e.g. due to a missing self-signature)
  d = The key has been disabled
      (deprecated - use the 'D' in field 12 instead)
  r = The key has been revoked
  e = The key has expired
  - = Unknown trust (i.e. no value assigned)
  q = Undefined trust
      '-' and 'q' may safely be treated as the same
      value for most purposes
  n = Don't trust this key at all
  m = There is marginal trust in this key
  f = The key is fully trusted
  u = The key is ultimately trusted.  This often means
      that the secret key is available, but any key may
      be marked as ultimately trusted.

=over 4

=item key_id

Key id to query for.

=back

=head1 AUTHOR

Joern Reder <joern AT zyn.de>

=head1 CONTACT

You can contact me by email. Please place the module name
"Mail::GPG" somewhere in the subject, because I filter
my mails that way. I'm a native German speaker, but you
can contact me in english as well.

=head1 COPYRIGHT

Copyright (C) 2004-2006 by Joern Reder, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Mail::GPG::Result, perl(1).

=cut

1;
