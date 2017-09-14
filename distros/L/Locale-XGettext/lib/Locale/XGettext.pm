#! /bin/false
# vim: ts=4:et

# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warrant y of
# MERCHANTABILITY or  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

# ABSTRACT: Extract Strings To PO Files

package Locale::XGettext;

use strict;

use Locale::TextDomain 1.20 qw(Locale-XGettext);
use File::Spec;
use Locale::PO 0.27;
use Scalar::Util qw(reftype blessed);
use Locale::Recode;
use Getopt::Long 2.36 qw(GetOptionsFromArray);

use Locale::XGettext::Util::POEntries;
use Locale::XGettext::Util::Keyword;
use Locale::XGettext::Util::Flag;

# Helper method, not exported!
sub __empty($) {
    my ($what) = @_;

    return if defined $what && length $what;

    return 1;
}

sub new {
    my ($class, $options, @files) = @_;

    my $self;
    if (ref $class) {
        $self = $class;
    } else {
        $self = bless {}, $class;
    }

    $self->{__options} = $options;
    $self->{__comment_tag} = undef;
    $self->{__files} = [@files];
    $self->{__exclude} = {};

    if (__PACKAGE__ eq ref $self) {
        require Carp;
        Carp::croak(__x("{package} is an abstract base class and must not"
                        . " be instantiated directly",
                        package => __PACKAGE__));
    }
    
    $options->{default_domain} = 'messages' if __empty $options->{default_domain};
    $options->{from_code} = 'ASCII' if __empty $options->{default_domain};
    $options->{output_dir} = '.' if __empty $options->{output_dir};

    if (exists $options->{add_location}) {
        my $option = $options->{add_location};
        if (__empty $option) {
            $option = 'full';
        }
        die __"The argument to '--add-location' must be 'full', 'file', or 'never'.\n"
            if $option ne 'full' && $option ne 'file' && $option ne 'never';
    }

    if (exists $options->{add_comments}) {
        if (!ref $options->{add_comments} 
            && 'ARRAY' ne $options->{add_comments}) {
            die __"Option 'add_comments' must be an array reference.\n";
        }
        
        foreach my $comment (@{$options->{add_comments}}) {
            $comment =~ s/^[ \t\n\f\r\013]+//;
            $comment = quotemeta $comment;
        }
    }
    
    $options->{from_code} = 'ASCII' if __empty $options->{from_code};

    my $from_code = $options->{from_code};
    my $cd = Locale::Recode->new(from => $from_code,
                                 to => 'utf-8');
    if ($cd->getError) {        
        warn __x("warning: '{from_code}' is not a valid encoding name.  "
                 . "Using ASCII as fallback.",
                 from_code => $from_code);
        $options->{from_code} = 'ASCII';
    } else {
        $options->{from_code} = 
            Locale::Recode->resolveAlias($options->{from_code});
    }
    
    $self->__readFilesFrom($options->{files_from});
    if ($self->needInputFiles) {
        $self->__usageError(__"no input file given") if !@{$self->{__files}};
    }
    
    $self->{__keywords} = $self->__setKeywords($options->{keyword});
    $self->{__flags} = $self->__setFlags($options->{flag});

    if (exists $options->{exclude_file} && !ref $options->{exclude_file}) {
        $options->{exclude_file} = [$options->{exclude_file}];
    }

    $self->__readExcludeFiles($options->{exclude_file});

    return $self;
}

sub newFromArgv {
    my ($class, $argv) = @_;

    my $self;
    if (ref $class) {
        $self = $class;
    } else {
        $self = bless {}, $class;
    }

    my %options = eval { $self->__getOptions($argv) };
    if ($@) {
        $self->__usageError($@);
    }
    
    $self->__displayUsage if $options{help};
    
    if ($options{version}) {
        print $self->versionInformation;
        exit 0;
    }
    
    return $class->new(\%options, @$argv);
}

sub defaultKeywords {
    return [];
}

sub defaultFlags {
    return [];
}

sub run {
    my ($self) = @_;

    if ($self->{__run}++) {
        require Carp;
        Carp::croak(__"Attempt to re-run extractor");
    }

    my $po = $self->{__po} = Locale::XGettext::Util::POEntries->new;
    
    if ($self->option('join_existing')) {
        my $output_file = $self->__outputFilename;
        if ('-' eq $output_file) {
            $self->__usageError(__"--join-existing cannot be used when output"
                                  . " is written to stdout");
        }
        $self->readPO($output_file);
    }
    
    foreach my $filename (@{$self->{__files}}) {
        my $path = $self->resolveFilename($filename)
            or die __x("Error resolving file name '{filename}': {error}!\n",
                       filename => $filename, error => $!);
        if ($path =~ /\.pot?$/i) {
            $self->readPO($path);
        } else {
            $self->readFile($path);
        }
    }

    $self->extractFromNonFiles;
    
    # FIXME! Sort po!
    
    if (($po->entries || $self->{__options}->{force_po})
        && !$self->{__options}->{omit_header}) {
        $po->prepend($self->__poHeader);
    }

    foreach my $entry ($po->entries) {
        $self->recodeEntry($entry);
    }

    return $self;
}

sub extractFromNonFiles { shift }

sub resolveFilename {
    my ($self, $filename) = @_;
    
    my $directories = $self->{__options}->{directory} || [''];
    foreach my $directory (@$directories) {
        my $path = length $directory 
            ? File::Spec->catfile($directory, $filename) : $filename;
        stat $path && return $path;
    }
    
    return;
}

sub po {
    shift->{__po}->entries;
}

sub readPO {
    my ($self, $path) = @_;
    
    my $entries = Locale::PO->load_file_asarray($path)
        or die __x("error reading '{filename}': {error}!\n",
                   filename => $path, error => $!);
    
    foreach my $entry (@$entries) {
        if ('""' eq $entry->msgid
            && __empty $entry->dequote($entry->msgctxt)) {
            next;
        }
        $self->addEntry($entry);
    }
    
    return $self;
}

sub addEntry {
    my ($self, $entry) = @_;

    if (!$self->{__run}) {
        require Carp;
        # TRANSLATORS: run() is a method that should be invoked first. 
        Carp::croak(__"Attempt to add entries before run");
    }

    # Simplify calling from languages that do not have hashes.
    if (!ref $entry) {
        $entry = {splice @_, 1};
    }

    my $comment = delete $entry->{automatic};
    $entry = $self->__promoteEntry($entry);

    if (defined $comment) {
        # Does it contain an "xgettext:" comment?  The original implementation
        # is quite relaxed here, even recogizing comments like "exgettext:".
        my $cleaned = '';
        $comment =~ s{
                  (.*?)xgettext:(.*?(?:\n|\Z))
              }{
                  my ($lead, $string) = ($1, $2);
                  my $valid;
                            
                  my @tokens = split /[ \x09-\x0d]+/, $string;
                            
                  foreach my $token (@tokens) {
                      if ($token eq 'fuzzy') {
                          $entry->fuzzy(1);
                          $valid = 1;
                      } elsif ($token eq 'no-wrap') {
                            $entry->add_flag('no-wrap');
                            $valid = 1;
                      } elsif ($token eq 'wrap') {
                          $entry->add_flag('wrap');
                          $valid = 1;
                      } elsif ($token =~ /^[a-z]+-(?:format|check)$/) {
                            $entry->add_flag($token);
                            $valid = 1;
                      }
                  }
                            
                  $cleaned .= "${lead}xgettext:${string}" if !$valid;
              }exg;

        $cleaned .= $comment;
        $comment = $cleaned;

        my $comment_keywords = $self->option('add_comments');
        if (!__empty $comment && defined $comment_keywords) {
            my @automatic;
            foreach my $keyword (@$comment_keywords) {
                if ($comment =~ /($keyword.*)/s) {
                    push @automatic, $1;
                    last;
                }
            }
            
            my $old_automatic = $entry->automatic;
            push @automatic, $entry->dequote($old_automatic) if !__empty $old_automatic;
            $entry->automatic(join "\n", @automatic) if @automatic;    
        }
    }
    
    my ($msgid) = $entry->msgid;
    if (!__empty $msgid) {
        my $ctx = $entry->msgctxt;
        $ctx = '' if __empty $ctx;
        
        return $self if exists $self->{__exclude}->{$msgid}->{$ctx};
    }
    
    $self->{__po}->add($entry);

    return $self;
}

sub keywords {
    my ($self) = @_;

    my %keywords = %{$self->{__keywords}};

    return \%keywords;
}

sub keywordOptionStrings {
    my ($self) = @_;

    my @keywords;
    my $keywords = $self->keywords;
    foreach my $function (keys %$keywords) {
        push @keywords, $keywords->{$function}->dump;
    }

    return \@keywords;
}

sub flags {
    my ($self) = @_;

    my @flags = @{$self->{__flags}};

    return \@flags;
}

sub flagOptionStrings {
    my ($self) = @_;

    my @flags;
    my $flags = $self->flags;
    foreach my $flag (@$flags) {
        push @flags, $flag->dump;
    }

    return \@flags;
}

sub recodeEntry {
    my ($self, $entry) = @_;
    
    my $from_code = $self->option('from_code');
    $from_code = 'US-ASCII' if __empty $from_code;
    $from_code = Locale::Recode->resolveAlias($from_code);
    
    my $cd;
    if ($from_code ne 'US-ASCII' && $from_code ne 'UTF-8') {
        $cd = Locale::Recode->new(from => $from_code, to => 'utf-8');
        die $cd->getError if defined $cd->getError;
    }

    my $toString = sub {
        my ($entry) = @_;

        return join '', map { defined $_ ? $_ : '' }
            $entry->msgid, $entry->msgid_plural, 
            $entry->msgctxt, $entry->comment;
    };
    
    if ($from_code eq 'US-ASCII') {        
        # Check that everything is 7 bit.
        my $flesh = $toString->($entry);
        if ($flesh !~ /^[\000-\177]*$/) {
            die __x("Non-ASCII string at '{reference}'.\n"
                    . "    Please specify the source encoding through "
                    . "'--from-code'.\n",
                    reference => $entry->reference);
        }
    } elsif ($from_code eq 'UTF-8') {
        # Check that utf-8 is valid.
        require utf8; # [SIC!]
        
        my $flesh = $toString->($entry);
        if (!utf8::valid($flesh)) {
            die __x("{reference}: invalid multibyte sequence\n",
                    reference => $entry->reference);
        }
    } else {
        # Convert.
        my $msgid = Locale::PO->dequote($entry->msgid);
        if (!__empty $msgid) {
            $cd->recode($msgid) 
                or $self->__conversionError($entry->reference, $cd);
            $entry->msgid($msgid);
        }
        
        my $msgid_plural = Locale::PO->dequote($entry->msgid_plural);
        if (!__empty $msgid_plural) {
            $cd->recode($msgid_plural) 
                or $self->__conversionError($entry->reference, $cd);
            $entry->msgid($msgid_plural);
        }
        
        my $msgstr = Locale::PO->dequote($entry->msgstr);
        if (!__empty $msgstr) {
            $cd->recode($msgstr) 
                or $self->__conversionError($entry->reference, $cd);
            $entry->msgid($msgstr);
        }
        
        my $msgstr_n = Locale::PO->dequote($entry->msgstr_n);
        if ($msgstr_n) {
            my $msgstr_0 = Locale::PO->dequote($msgstr_n->{0});
            $cd->recode($msgstr_0) 
                or $self->__conversionError($entry->reference, $cd);
            my $msgstr_1 = Locale::PO->dequote($msgstr_n->{1});
            $cd->recode($msgstr_1) 
                or $self->__conversionError($entry->reference, $cd);
            $entry->msgstr_n({
                0 => $msgstr_0,
                1 => $msgstr_1,
            })
        }
        
        my $comment = $entry->comment;
        $cd->recode($comment) 
            or $self->__conversionError($entry->reference, $cd);
        $entry->comment($comment);
    }

    return $self;        
}

sub options {
    shift->{__options};
}

sub option {
    my ($self, $key) = @_;

    return if !exists $self->{__options}->{$key};
    
    return $self->{__options}->{$key};
}

sub output {
    my ($self) = @_;
    
    if (!$self->{__run}) {
        require Carp;
        Carp::croak(__"Attempt to output from extractor before run");
    }
    
    if (!$self->{__po}) {
        require Carp;
        Carp::croak(__"No PO data");
    }
    
    return if !$self->{__po}->entries && !$self->{__options}->{force_po};

    my $options = $self->{__options};
    my $filename = $self->__outputFilename;

    open my $fh, '>', $filename
        or die __x("Error writing '{file}': {error}.\n",
                   file => $filename, error => $!);
    
    foreach my $entry ($self->{__po}->entries) {
        print $fh $entry->dump
            or die __x("Error writing '{file}': {error}.\n",
                       file => $filename, error => $!);
    }
    close $fh
        or die __x("Error writing '{file}': {error}.\n",
                   file => $filename, error => $!);
    
    return $self;
}

sub languageSpecificOptions {}

# In order to simplify the code in other languages, we allow returning
# a flat list instead of an array of arrays.  This wrapper checks the
# return value and converts it accordingly.
sub __languageSpecificOptions {
    my ($self) = @_;

    my @options = $self->languageSpecificOptions;
    return $options[0] if @options & 0x3;

    # Number of items is a multiple of 4.
    my @retval;
    while (@options) {
            push @retval, [splice @options, 0, 4];
    }

    return \@retval;
}

sub printLanguageSpecificUsage {
    my ($self) = @_;
  
    my $options = $self->__languageSpecificOptions;
    
    foreach my $optspec (@{$options || []}) {
        my ($optstring, $optvar,
            $usage, $description) = @$optspec;
        
        print "  $usage ";
        my $pos = 3 + length $usage;
        
        my @description = split /[ \x09-\x0d]+/, $description;
        my $lineno = 0;
        while (@description) {
            my $limit = $lineno ? 31 : 29;
            if ($pos < $limit) {
                print ' ' x ($limit - $pos);
                $pos = $limit;
            }
            
            while (@description) {
                my $word = shift @description;
                print " $word";
                $pos += 1 + length $word;
                if (@description && $pos > 77 - length $description[-1]) {
                    ++$lineno;
                    print "\n";
                    $pos = 0;
                    last;
                }
            }
        }
        print "\n";
    }
    
    return $self;
}

sub fileInformation {}

sub bugTrackingAddress {}

sub versionInformation {
    my ($self) = @_;
    
    my $package = ref $self;

    my $version;
    {
        ## no critic
        no strict 'refs';

        my $varname = "${package}::VERSION";
        $version = ${$varname};
    };

    $version = '' if !defined $version;
    
    $package =~ s/::/-/g;
    
    return __x('{program} ({package}) {version}
Please see the source for copyright information!
', program => $0, package => $package, version => $version);
}

sub canExtractAll {
    return;
}

sub canKeywords {
    shift;
}

sub canFlags {
    shift;
}

sub needInputFiles {
    shift;
}

sub __readExcludeFiles {
    my ($self, $files) = @_;
    
    return $self if !$files;
    
    foreach my $file (@$files) {
       my $entries = Locale::PO->load_file_asarray($file)
        or die __x("error reading '{filename}': {error}!\n",
                   filename => $file, error => $!);
    
        foreach my $entry (@$entries) {
            my $msgid = $entry->msgid;
            next if __empty $msgid;
            
            my $ctx = $entry->msgctxt;
            $ctx = '' if __empty $ctx;
            
            $self->{__exclude}->{$msgid}->{$ctx} = $entry;
        }
    }
    
    return $self;
}

sub __promoteEntry {
    my ($self, $entry) = @_;
    
    if (!blessed $entry) {
        my %entry = %$entry;
        my $po_entry = Locale::PO->new;

        my $keyword = delete $entry{keyword};
        if (defined $keyword) {
            my $keywords = $self->keywords;
            if (exists $keywords->{$keyword}) {
                my $comment = $keywords->{$keyword}->comment;
                $entry{automatic} = $comment if !__empty $comment;

                my $flags = $self->flags;
                my $sg_arg = $keywords->{$keyword}->singular;
                my $pl_arg = $keywords->{$keyword}->plural || 0;
                foreach my $flag (@$flags) {
                    next if $keyword ne $flag->function;
                    next if $flag->arg != $sg_arg && $flag->arg != $pl_arg;
                    my $flag_name = $flag->flag;
                    $flag_name = 'no-' . $flag_name if $flag->no;
                    $po_entry->add_flag($flag_name);
                }
            }
        }

        my $flags = delete $entry{flags};
        if (defined $flags) {
            my @flags = split /[ \t\r\n]*,[ \t\r\n]*/, $flags;
            foreach my $flag (@flags) {
                $po_entry->add_flag($flag)
                    if !$po_entry->has_flag($flag);
            }
        }

        foreach my $method (keys %entry) {
            eval { $po_entry->$method($entry{$method}) };
            warn __x("error calling method '{method}' with value '{value}'"
                     . " on Locale::PO instance: {error}.\n",
                     method => $method, value => $entry{$method},
                     error => $@) if $@;
        }

        $entry = $po_entry;
    }

    return $entry;
}

sub __conversionError {
    my ($self, $reference, $cd) = @_;
    
    die __x("{reference}: {conversion_error}\n",
            reference => $reference,
            conversion_error => $cd->getError);
}

sub __outputFilename {
    my ($self) = @_;
    
    my $options = $self->{__options};
    if (exists $options->{output}) {
        if (File::Spec->file_name_is_absolute($options->{output})
            || '-' eq $options->{output}) {
            return $options->{output}; 
        } else {
            return File::Spec->catfile($options->{output_dir},
                                       $options->{output})
        }
    } elsif ('-' eq $options->{default_domain}) {
        return '-';
    } else {
        return File::Spec->catfile($options->{output_dir}, 
                                   $options->{default_domain} . '.po');
    }
    
    # NOT REACHED!
}
sub __poHeader {
    my ($self) = @_;

    my $options = $self->{__options};
    
    my $user_info;
    if ($options->{foreign_user}) {
        $user_info = <<EOF;
This file is put in the public domain.
EOF
    } else {
        my $copyright = $options->{copyright_holder};
        $copyright = "THE PACKAGE'S COPYRIGHT HOLDER" if !defined $copyright;
        
        $user_info = <<EOF;
Copyright (C) YEAR $copyright
This file is distributed under the same license as the PACKAGE package.
EOF
    }
    chomp $user_info;
    
    my $entry = Locale::PO->new;
    $entry->fuzzy(1);
    $entry->comment(<<EOF);
SOME DESCRIPTIVE TITLE.
$user_info
FIRST AUTHOR <EMAIL\@ADDRESS>, YEAR.
EOF
    $entry->msgid('');

    my @fields;
    
    my $package_name = $options->{package_name};
    if (defined $package_name) {
        my $package_version = $options->{package_version};
        $package_name .= ' ' . $package_version 
            if defined $package_version && length $package_version; 
    } else {
        $package_name = 'PACKAGE VERSION'
    }
    
    push @fields, "Project-Id-Version: $package_name";

    my $msgid_bugs_address = $options->{msgid_bugs_address};
    $msgid_bugs_address = '' if !defined $msgid_bugs_address;
    push @fields, "Report-Msgid-Bugs-To: $msgid_bugs_address";    
    
    push @fields, 'Last-Translator: FULL NAME <EMAIL@ADDRESS>';
    push @fields, 'Language-Team: LANGUAGE <LL@li.org>';
    push @fields, 'Language: ';
    push @fields, 'MIME-Version: ';
    # We always write utf-8.
    push @fields, 'Content-Type: text/plain; charset=UTF-8';
    push @fields, 'Content-Transfer-Encoding: 8bit';
    
    $entry->msgstr(join "\n", @fields);    
    return $entry;
}

sub __getEntriesFromFile {
    my ($self, $filename) = @_;

    open my $fh, '<', $filename
        or die __x("Error reading '{filename}': {error}!\n",
                   filename => $filename, error => $!);
    
    my @entries;
    my $chunk = '';
    my $last_lineno = 1;
    while (my $line = <$fh>) {
        if ($line =~ /^[\x09-\x0d ]*$/) {
            if (length $chunk) {
                my $entry = Locale::PO->new;
                chomp $chunk;
                $entry->msgid($chunk);
                $entry->reference("$filename:$last_lineno");
                push @entries, $entry;
            }
            $last_lineno = $. + 1;
            $chunk = '';
        } else {
            $chunk .= $line;
        }
    }
    
    if (length $chunk) {
        my $entry = Locale::PO->new;
        $entry->msgid($chunk);
        chomp $chunk;
        $entry->reference("$filename:$last_lineno");
        push @entries, $entry;
    }

    return @entries;
}

sub __readFilesFrom {
    my ($self, $list) = @_;
    
    my %seen;
    my @files;
    foreach my $file (@{$self->{__files}}) {
        my $canonical = File::Spec->canonpath($file);
        push @files, $file if !$seen{$canonical}++;
    }
    
    # This matches the format expected by GNU xgettext.  Lines where the
    # first non-whitespace character is a hash sign, are ignored.  So are
    # empty lines (after whitespace stripping).  All other lines are treated
    # as filenames with trailing (not leading!) space stripped off.
    foreach my $potfile (@$list) {
        open my $fh, '<', $potfile
            or die __x("Error opening '{file}': {error}!\n",
                       file => $potfile, error => $!);
        while (my $file = <$fh>) {
            next if $file =~ /^[ \x09-\x0d]*#/;
            $file =~ s/[ \x09-\x0d]+$//;
            next if !length $file;
            
            my $canonical = File::Spec->canonpath($file);
            next if $seen{$canonical}++;

            push @files, $file;
        }
    }
    
    $self->{__files} = \@files;
    
    return $self;
}

sub __getOptions {
    my ($self, $argv) = @_;
    
    my %options;
    
    my $lang_options = $self->__languageSpecificOptions;
    my %lang_options;
    
    foreach my $optspec (@$lang_options) {
        my ($optstring, $optvar,
            $usage, $description) = @$optspec;
        $lang_options{$optstring} = \$options{$optvar};
    }
    
    Getopt::Long::Configure('bundling');
    $SIG{__WARN__} = sub {
        $SIG{__WARN__} = 'DEFAULT';
        die shift;
    };
    GetOptionsFromArray($argv,
        # Are always overridden by standard options.
        %lang_options,
        
        # Input file location:
        'f|files-from=s@' => \$options{files_from},
        'D|directory=s@' => \$options{directory},

        # Output file location:
        'd|default-domain=s' => \$options{default_domain},
        'o|output=s' => \$options{output},
        'p|output-dir=s' => \$options{output_dir},

        # Input file interpretation.
        'from-code=s' => \$options{from_code},
       
        # Operation mode:
        'j|join-existing' => \$options{join_existing},
        
        # We allow multiple files.
        'x|exclude-file=s@' => \$options{exclude_file},
        'c|add-comments:s@' => \$options{add_comments},

        # Language specific options:
        'a|extract-all' => \$options{extract_all},
        'k|keyword:s@' => \$options{keyword},
        'flag:s@' => \$options{flag},
         
        # Output details:
        'force-po' => \$options{force_po},
        'no-location' => \$options{no_location},
        'n|add-location' => \$options{add_location},
        's|sort-output' => \$options{sort_output},
        'F|sort-by-file' => \$options{sort_by_file},
        'omit-header' => \$options{omit_header},
        'copyright-holder=s' => \$options{copyright_holder},
        'foreign-user' => \$options{foreign_user},
        'package_name=s' => \$options{package_name},
        'package_version=s' => \$options{package_version},
        'msgid-bugs-address=s' => \$options{msgid_bugs_address},
        'm|msgstr-prefix:s' => \$options{msgid_str_prefix},
        'M|msgstr-suffix:s' => \$options{msgid_str_suffix},

        # Informative output.
        'h|help' => \$options{help},
        'V|version' => \$options{version},
    );
    $SIG{__WARN__} = 'DEFAULT';
    
    foreach my $key (keys %options) {
        delete $options{$key} if !defined $options{$key};
    }
    
    return %options;   
}

sub __setKeywords {
    my ($self, $options) = @_;

    my $defaults = $self->defaultKeywords || [];
    
    my $keywords = {};
    foreach my $option (@$defaults, @$options) {
        if ('' eq $option) {
            $keywords = {};
            next;
        }

        my $keyword;
        if (ref $option) {
            $keyword = $option;
        } else {
            $keyword = Locale::XGettext::Util::Keyword->newFromString($option);
        }
        $keywords->{$keyword->function} = $keyword;
    }

    return $keywords;
}

sub __setFlags {
    my ($self, $options) = @_;
    
    my @defaults = @{$self->defaultFlags};

    my %flags;
    my @flags;

    foreach my $spec (@defaults, @$options) {
        my $obj = Locale::XGettext::Util::Flag->newFromString($spec)
            or die __x("A --flag argument doesn't have the"
                       . " <keyword>:<argnum>:[pass-]<flag> syntax: {flag}",
                       $spec);
        my $function = $obj->function;
        my $arg = $obj->arg;
        my $flag = $obj->flag;

        # First one wins.
        next if $flags{$function}->{$flag}->{$arg};

        $flags{$function}->{$flag}->{$arg} = $obj;
        push @flags, $obj;
    }
    
    return \@flags;
}

sub __displayUsage {
    my ($self) = @_;
    
    if ($self->needInputFiles) {
        print __x("Usage: {program} [OPTION] [INPUTFILE]...\n", program => $0);
        print "\n";
    
        print __(<<EOF);
Extract translatable strings from given input files.
EOF
    } else {
        print __x("Usage: {program} [OPTION]\n", program => $0);
        print "\n";
    
        print __(<<EOF);
Extract translatable strings.
EOF
    }
    
    if (defined $self->fileInformation) {
        print "\n";
        my $description = $self->fileInformation;
        chomp $description;
        print "$description\n";
    }

    print "\n";
    
    print __(<<EOF);
Mandatory arguments to long options are mandatory for short options too.
Similarly for optional arguments.
EOF

    print "\n";

        print __(<<EOF);
Input file location:
EOF

    print __(<<EOF);
  INPUTFILE ...               input files
EOF

    print __(<<EOF);
  -f, --files-from=FILE       get list of input files from FILE\
EOF

    print __(<<EOF);
  -D, --directory=DIRECTORY   add DIRECTORY to list for input files search
EOF

    printf __(<<EOF);
If input file is -, standard input is read.
EOF

    print "\n";
    
    printf __(<<EOF);
Output file location:
EOF

    printf __(<<EOF);
  -d, --default-domain=NAME   use NAME.po for output (instead of messages.po)
EOF

    print __(<<EOF);
  -o, --output=FILE           write output to specified file
EOF

    print __(<<EOF);
  -p, --output-dir=DIR        output files will be placed in directory DIR
EOF

    print __(<<EOF);
If output file is -, output is written to standard output.
EOF

    print "\n";

    print __(<<EOF);
Input file interpretation:
EOF

    print __(<<EOF);
      --from-code=NAME        encoding of input files
EOF
    print __(<<EOF);
By default the input files are assumed to be in ASCII.
EOF

    printf "\n";

    print __(<<EOF);
Operation mode:
EOF

    print __(<<EOF);
  -j, --join-existing         join messages with existing file
EOF

    print __(<<EOF);
  -x, --exclude-file=FILE.po  entries from FILE.po are not extracted
EOF

    print __(<<EOF);
  -cTAG, --add-comments=TAG   place comment blocks starting with TAG and
                                preceding keyword lines in output file
  -c, --add-comments          place all comment blocks preceding keyword lines
                                in output file
EOF

    print "\n";

    print __(<<EOF);
Language specific options:
EOF

    if ($self->canExtractAll) {
        print __(<<EOF);
  -a, --extract-all           extract all strings
EOF
    }

    if ($self->canKeywords) {
        print __(<<EOF);
  -kWORD, --keyword=WORD      look for WORD as an additional keyword
  -k, --keyword               do not to use default keywords"));
      --flag=WORD:ARG:FLAG    additional flag for strings inside the argument
                              number ARG of keyword WORD
EOF
    }

    $self->printLanguageSpecificUsage;

    print "\n";

    print __(<<EOF);
Output details:
EOF

    print __(<<EOF);
      --force-po              write PO file even if empty
EOF

    print __(<<EOF);
      --no-location           do not write '#: filename:line' lines
EOF

    print __(<<EOF);
  -n, --add-location          generate '#: filename:line' lines (default)
EOF

    print __(<<EOF);
  -s, --sort-output           generate sorted output
EOF

    print __(<<EOF);
  -F, --sort-by-file          sort output by file location
EOF

    print __(<<EOF);
      --omit-header           don't write header with 'msgid ""' entry
EOF

    print __(<<EOF);
      --copyright-holder=STRING  set copyright holder in output
EOF

    print __(<<EOF);
      --foreign-user          omit FSF copyright in output for foreign user
EOF

    print __(<<EOF);
      --package-name=PACKAGE  set package name in output
EOF

    print __(<<EOF);
      --package-version=VERSION  set package version in output
EOF

    print __(<<EOF);
      --msgid-bugs-address=EMAIL\@ADDRESS  set report address for msgid bugs
EOF

    print __(<<EOF);
  -m[STRING], --msgstr-prefix[=STRING]  use STRING or "" as prefix for msgstr
                                values
EOF

    print __(<<EOF);
  -M[STRING], --msgstr-suffix[=STRING]  use STRING or "" as suffix for msgstr
                                values
EOF

    printf "\n";

    print __(<<EOF);
Informative output:
EOF

    print __(<<EOF);
  -h, --help                  display this help and exit
EOF

    print __(<<EOF);
  -V, --version               output version information and exit
EOF

    my $url = $self->bugTrackingAddress;

    printf "\n";

    if (defined $url) {
        # TRANSLATORS: The placeholder indicates the bug-reporting address
        # for this package.  Please add _another line_ saying
        # "Report translation bugs to <...>\n" with the address for translation
        # bugs (typically your translation team's web or email address).
        print __x("Report bugs at <{URL}>!\n", URL => $url);
    }

    exit 0;
}

sub __usageError {
    my ($self, $message) = @_;

    if ($message) {
        $message =~ s/\s+$//;
        $message = __x("{program_name}: {error}\n",
                       program_name => $0, error => $message);
    } else {
        $message = '';
    }
    
    die $message . __x("Try '{program_name} --help' for more information!\n",
                       program_name => $0);
}

1;
