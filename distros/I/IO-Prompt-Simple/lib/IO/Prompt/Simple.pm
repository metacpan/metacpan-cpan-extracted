package IO::Prompt::Simple;

use strict;
use warnings;
use 5.006001;
use base 'Exporter';

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1 if $^O eq 'MSWin32';
}

our $VERSION = '0.06';

our @EXPORT = 'prompt';

sub prompt {
    my ($message, $opts) = @_;
    _croak('Usage: prompt($message, [$default_or_opts])') unless defined $message;

    my $default;
    if (ref $opts eq 'HASH') {
        $default = $opts->{default};
    }
    else {
        ($default, $opts) = ($opts, {});
    }
    my $display_default = defined $default ? "[$default]" : '';
    $default = defined $default ? $default : '';

    my $stash = { message => $message };
    _parse_option($opts, $stash);

    $stash->{message} .= " $display_default";
    if (my $color = $opts->{color}) {
        require Term::ANSIColor;
        $color = [$color] unless ref $color eq 'ARRAY';
        $stash->{message} = Term::ANSIColor::colored($color, $stash->{message});
    }

    my ($in, $out) = @$stash{qw/in out/};

    # autoflush and reset format for output
    my $org_out = select $out;
    local $| = 1;
    local $\;
    select $org_out;

    my $ignore_case = $opts->{ignore_case} ? 1 : 0;
    my $isa_tty     = _isa_tty($in, $out);
    my $answer;
    my @answers; # for multi
    while (1) {
        print {$out} $stash->{choices}, "\n" if defined $stash->{choices};
        print {$out} $stash->{message}, ': ';
        if ($ENV{PERL_IOPS_USE_DEFAULT} || $opts->{use_default} || (!$isa_tty && eof $in)) {
            print {$out} "$default\n";
            $answer = $default;
            last;
        }
        $answer = <$in>;
        if (defined $answer) {
            chomp $answer;
            print {$out} "$answer\n" unless $isa_tty;
        }
        else {
            print {$out} "\n";
        }

        $answer = $default if !defined $answer || $answer eq '';
        $answer = $stash->{encoder}->decode($answer) if defined $stash->{encoder};
        if (my $exclusive_map = $stash->{exclusive_map}) {
            if ($stash->{want_multi}) {
                $answer = $ignore_case ? lc $answer : $answer;
                my $has_error;
                for my $ans (split /\s+/, $answer) {
                    unless (exists $exclusive_map->{$ans}) {
                        $has_error = 1;
                        last;
                    }
                    push @answers, $exclusive_map->{$ans};
                }
                $has_error = 1 unless @answers;
                last unless $has_error;
            }
            else {
                if (exists $exclusive_map->{$ignore_case ? lc $answer : $answer}) {
                    $answer = $exclusive_map->{$ignore_case ? lc $answer : $answer};
                    last;
                }
            }
            @answers = ();
            $answer  = undef;
            print {$out} $stash->{hint};
            next;
        }
        elsif (my $regexp = $stash->{regexp}) {
            last if $answer =~ $regexp;
            $answer = undef;
            print {$out} $stash->{hint};
            next;
        }
        last;
    }

    return $stash->{want_multi} ? @answers : $answer;
}

sub _parse_option {
    my ($opts, $stash) = @_;

    $stash->{in}  = _is_fh($opts->{input})  ? $opts->{input}  : *STDIN;
    $stash->{out} = _is_fh($opts->{output}) ? $opts->{output} : *STDOUT;

    if ($opts->{yn}) {
        $opts->{anyone}       = \[y => 1, n => 0];
        $opts->{ignore_case}  = 1 unless exists $opts->{ignore_case};
    }

    $opts->{anyone} ||= $opts->{choices};
    if ($opts->{anyone}) {
        $stash->{exclusive_map} = _make_exclusive_map($opts, $stash);
        $stash->{want_multi}    = $opts->{multi} ? 1 : 0;
    }
    elsif ($opts->{regexp}) {
        $stash->{regexp} = _make_regexp($opts, $stash);
    }

    if ($opts->{encode}) {
        require Encode;
        $stash->{encoder} = Encode::find_encoding($opts->{encode});
    }
}

sub _make_exclusive_map {
    my ($opts, $stash) = @_;
    my $anyone = $opts->{anyone};
    my $exclusive_map = {};

    my $ignore_case = $opts->{ignore_case} ? 1 : 0;
    my ($message, $hint, $choices) = @$stash{qw/message hint choices/};
    my $type = _anyone_type($anyone) || return;
    if ($type eq 'ARRAY') {
        my @stuffs = _uniq(@$anyone);
        for my $stuff (@stuffs) {
            $exclusive_map->{$ignore_case ? lc $stuff : $stuff} = $stuff;
        }
        $hint     = sprintf "# Please answer %s\n", join ' or ', map qq{`$_`}, @stuffs;
        $message .= sprintf ' (%s)', join '/', @stuffs;
    }
    elsif ($type eq 'HASH' || $type eq 'REFARRAY' || $type eq 'Hash::MultiValue') {
        my @keys =
            $type eq 'HASH'             ? sort { $a cmp $b } keys %$anyone :
            $type eq 'REFARRAY'         ? do { my $i = 0; grep { ++$i % 2 == 1 } @{$$anyone} } :
            $type eq 'Hash::MultiValue' ? $anyone->keys : ();
        my $max = 0;
        my $idx = 1;
        for my $key (@keys) {
            $max = length $key > $max ? length $key : $max;
            $exclusive_map->{$ignore_case ? lc $key : $key} =
                $type eq 'REFARRAY' ? $$anyone->[$idx] : $anyone->{$key};
            $idx += 2;
        }
        $hint = sprintf "# Please answer %s\n", join ' or ',map qq{`$_`}, @keys;
        if ($opts->{verbose}) {
            my $idx = -1;
            $choices = join "\n", map {
                $idx += 2;
                sprintf "# %-*s => %s", $max, $_,
                    $type eq 'REFARRAY' ? $$anyone->[$idx] : $anyone->{$_};
            } @keys;
        }
        else {
            $message .= sprintf ' (%s)', join '/', @keys;
        }
    }

    @$stash{qw/message hint choices/} = ($message, $hint, $choices);
    return $exclusive_map;
}

sub _anyone_type {
    my $anyone = shift;
    my $type =
        ref $anyone eq 'ARRAY' && @$anyone ? 'ARRAY' :
        ref $anyone eq 'HASH'  && %$anyone ? 'HASH'  :
        ref $anyone eq 'REF'   && ref $$anyone eq 'ARRAY' && @{$$anyone}
            ? 'REFARRAY' :
        do {
            require Scalar::Util;
            Scalar::Util::blessed($anyone) || ''
        } eq 'Hash::MultiValue' && %$anyone
            ? 'Hash::MultiValue' : '';
    return $type;
}

sub _make_regexp {
    my ($opts, $stash) = @_;
    my $regexp = ref $opts->{regexp} eq 'Regexp' ? $opts->{regexp}
        : $opts->{ignore_case} ? qr/$opts->{regexp}/i : qr/$opts->{regexp}/;
    $stash->{hint} = sprintf "# Please answer pattern %s\n", $regexp;
    $regexp = qr/\A $regexp \Z/x;
    return $regexp;
}

# using IO::Interactive::is_interactive() ?
sub _isa_tty {
    my ($in, $out) = @_;
    return -t $in && (-t $out || !(-f $out || -c $out)) ? 1 : 0; ## no critic
}

# taken from Test::Builder
sub _is_fh {
    my $maybe_fh = shift;
    return 0 unless defined $maybe_fh;

    return 1 if ref $maybe_fh  eq 'GLOB'; # its a glob ref
    return 1 if ref \$maybe_fh eq 'GLOB'; # its a glob

    return eval { $maybe_fh->isa('IO::Handle') }
        || eval { tied($maybe_fh)->can('TIEHANDLE') };
}

sub _uniq {
    my %h;
    grep !$h{$_}++, @_;
}

sub _croak {
    require Carp;
    Carp::croak(@_);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

IO::Prompt::Simple - provide a simple user input

=head1 SYNOPSIS

  # foo.pl
  use IO::Prompt::Simple;

  my $answer = prompt 'some question...';
  print "answer: $answer\n";

  # display prompt message, and wait your input.
  $ foo.pl
  some question: foo[Enter]
  answer: foo

=head1 DESCRIPTION

IO::Prompt::Simple is porting L<< ExtUtils::MakeMaker >>'s prompt() function.

Added a few more useful features.

THIS MODULE IS ALPHA LEVEL INTERFACE!!

=head1 FUNCTIONS

=head2 prompt($message, [$default_or_option])

Display prompt message and wait your input.

  $answer = prompt $message;

Sets default value:

  $answer = prompt 'sets default', 'default';
  is $answer, 'default';

or

  $answer = prompt 'sets default', { default => 'default' };
  is $answer, 'default';

Display like are:

  sets default [default]: [Enter]
  ...

supported options are:

=over

=item default: SCALAR

Sets default value.

  $answer = prompt 'sets default', { default => 'default' };
  is $answer, 'default';

=item anyone: ARRAYREF | HASHREF | REF-ARRAYREF | Hash::MultiValue

Choose any one.

  $answer = prompt 'choose', { anyone => [qw/y n/] };

Display like are:

  choose (y/n) : [Enter]
  # Please answer `y` or `n`
  choose (y/n) : y[Enter]
  ...

If you specify HASHREF, returned value is HASHREF's value.

  $answer = prompt 'choose', { anyone => { y => 1, n => 0 } };
  is $answer, 1; # when you input is 'y'

And, when you specify the verbose option, you can tell the user more information.

  $answer = prompt 'choose your homepage', {
      anyone => {
          google => 'http://google.com/',
          yahoo  => 'http://yahoo.com/',
          bing   => 'http://bing.com/',
      },
      verbose => 1,
  };

Display like are:

  # bing   => http://bing.com/
  # google => http://google.com/
  # yahoo  => http://yahoo.com/
  choose your homepage : [Enter]
  # Please answer `bing` or `google` or `yahoo`
  choose your homepage : google[Enter]
  ...

If you want preserve the order of keys, you can use L<< Hash::MultiValue >>.

  $answer = prompt 'foo', { anyone => { b => 1, c => 2, a => 4 } }; # prompring => `foo (a/b/c) : `
  $answer = prompt 'foo', {
      anyone => Hash::MultiValue->new(b => 1, c => 2, a => 4)
  }; # prompring => `foo (b/c/a) : `

Or, you can use REF-ARRAYREF.

  $answer = prompt 'foo', { anyone => \[b => 1, c => 2, a => 4] };

=item choices

Alias of C<< anyone >>

=item multi: BOOL

Returned multiple answers. Your answer are evaluated separated by space.

  use Data::Dumper;
  @answers = prompt 'choices', {
      choices => [qw/a b c/],
      multi   => 1,
  };
  print Dumper \@answers;

Display like are:

  choices (a/b/c) : c a[Enter]
  $VAR1 = [
            'c',
            'a'
          ];

Or, you can specify HASHREF:

  use Data::Dumper;
  @answers = prompt 'choices', {
      choices => {
          google => 'http://google.com/',
          yahoo  => 'http://yahoo.com/',
          bing   => 'http://bing.com/',
      },
      verbose => 1,
      multi   => 1,
  };
  print Dumper \@answers;

Display like are:

  # bing   => http://bing.com/
  # google => http://google.com/
  # yahoo  => http://yahoo.com/
  choices: google yahoo[Enter]
  $VAR1 = [
            'http://google.com/',
            'http://yahoo.com/'
          ];

=item regexp: STR | REGEXP

Sets regexp for answer.

  $answer = prompt 'regexp', { regexp => '[0-9]{4}' };

Display like are:

  regexp : foo[Enter]
  # Please answer pattern (?^:[0-9{4}])
  regexp : 1234
  ...

It C<< regexp >> and C<< anyone >> is exclusive (C<< anyone >> is priority).

=item ignore_case: BOOL

Ignore case for anyone or regexp.

  # passed `Y` or `N`
  $answer = prompt 'ignore_case', {
      anyone      => [qw/y n/],
      ignore_case => 1,
  };

=item yn: BOOL

Shortcut of C<< { anyone => \[ y => 1, n => 0 ], ignore_case => 1 } >>.

  $answer = prompt 'are you ok?', { yn => 1 };

Display like are:

  are you ok? (y/n) : y[Enter]

=item use_default: BOOL

Force using for default value.
If not specified defaults to an empty string.

  $answer = prompt 'use default', {
      default     => 'foo',
      use_default => 1,
  };
  is $answer, 'foo';

I think, CLI's C<< --force >> like option friendly.

=item input: FILEHANDLE

Sets input file handle (default: STDIN)

  $answer = prompt 'input from DATA', { input => *DATA };
  is $answer, 'foobar';
  __DATA__
  foobar

=item output: FILEHANDLE

Sets output file handle (default: STDOUT)

  $answer = prompt 'output for file', { output => $fh };

=item encode: STR | Encoder

Sets encoding. If specified, returned a decoded string.

=item color: STR | ARRAYREF

Sets prompt color. Using L<< Term::ANSIColor >>.

  $answer = prompt 'colored prompting', { color => [qw/red on_white/] };

=back

=head1 NOTE

If prompt() detects that it is not running interactively
and there is nothing on C<< $input >>
or if the C<< $ENV{PERL_IOPS_USE_DEFAULT} >> is set to true
or C<< use_default >> option is set to true,
the C<< $default >> will be used without prompting.

This prevents automated processes from blocking on user input.

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - 2012 xaicron.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< ExtUtils::MakeMaker >>
L<< IO::Prompt >>

=cut
