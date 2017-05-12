#
# This file is part of Getopt-Mini
#
# This software is copyright (c) 2015 by Rodrigo de Oliveira.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Getopt::Mini;
use strict;
use warnings;
use Encode qw();

our $VERSION = '0.03';

sub import {
    my $class = shift;
    my %args = @_;
    if( defined $args{var} ) {
        if( $args{var} !~ /::/ ) {
            my $where = caller(0);
            $args{var} = $where . '::' . $args{var};
        }
        my %hash = getopt( arrays=>0 );
        no strict 'refs';
        *{ $args{var} } = \%hash;
    }
    elsif( defined $args{later} ) {
        # import getopt() so that user can call it
        my $where = caller(0);
        no strict 'refs';
        *{ $where . '::getopt' } = \&getopt;
    }
    else {
        # into %ARGV
        getopt( arrays=>0 );
    }
    #unshift @ARGV, @barewords;
    return;
}

sub getopt_array {
    getopt( arrays=>1 , @_ );
}

sub getopt {
    my ( $last_opt, $last_done, %hash );
    my %opts;
    # get my own opts
    my @argv = @_ == 0
      ? @ARGV
      : do {
           %opts = @_;
           @{ delete $opts{argv} || [] };
      };
    if (not @argv){ push(@argv, Encode::decode('UTF-8' ,$_) ) for @ARGV; }
    return () unless @argv;
    $hash{_argv} = [ @argv ];
    while(@argv) {
        my $arg = shift @argv;
        if ( $arg =~ m/^-(\w)$/ ) {   # single letter
            my $flag = $1;
            if( $opts{hungry_flags} && defined $argv[0] && $argv[0] !~ /^-/ ) {
                $hash{$flag} = shift @argv;
            } else {
                $hash{$flag} ++;
            }
            $last_done= 1;
        } 
        elsif ( $arg =~ m/^-+(.+)/ ) {
            $last_opt = $1;
            $last_done=0;
            if( $last_opt =~ m/^(.*)\=(.*)$/ ) {
                push @{ $hash{$1} }, $2 ;
                $last_done= 1;
            } else {
                $hash{$last_opt} = [] unless ref $hash{$last_opt};
            }
        }
        else {
            #$arg = Encode::encode_utf8($arg) if Encode::is_utf8($arg);
            $last_opt ='' if !$opts{arrays} && ( $last_done || ! defined $last_opt );
            push @{ $hash{$last_opt} }, $arg; 
            $last_done = 1;
        }
    }
    # convert single option => scalar
    for( keys %hash ) {
        next unless ref( $hash{$_} ) eq 'ARRAY';
        if( @{ $hash{$_} } == 0 ) {
            $hash{$_} = $opts{define} ? 1 : ();
        } elsif( @{ $hash{$_} } == 1 ) {
            $hash{$_} = $hash{$_}->[0];
        }
    }
    if( defined wantarray ) {
        return %hash;
    } else {
        %ARGV = %hash;
    }
}

sub getopt_validate {
    my %args = @_;
    $args{''}={isa=>'Any'};  # ignores this
    require Data::Validator;
    my $rule = Data::Validator->new( %args );
    @_ = ($rule, %ARGV );
    goto \&Data::Validator::validate;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Mini

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Getopt::Mini;
    say $ARGV{'flag'};

=head1 DESCRIPTION

This is, yup, yet another Getopt module, a very lightweight one. It's not declarative
in any way, ie, it does not support specs, like L<Getopt::Long> et al do.

On the other hand, it can validate your parameters using the L<Data::Validator> syntax.
But that's a hidden feature for now (you'll need to install L<Data::Validator> yourself
and find a way to run it by reading this source code).

=head1 NAME

Getopt::Mini

=head1 VERSION

version 0.02

=head1 NAME

Getopt::Mini - yet another yet-another Getopt module

=head1 VERSION

version 0.02

=head1 USAGE

The rules:

    * -<char>
        does not consume barewords (ie. -f, -h, ...)
        unless you set hungry_flags=>1

    * -<str> <bareword>
    * --<str> <bareword>
        will eat up the next bare word (-type f, --file f.txt)

    * -<char|str>=<val> and --<str>=<val>
        consumes its value and nothing more

    * <str>
        gets pushed into an array in $ARGV{''}

Some code examples:

    perl myprog.pl -h -file foo --file bar
    use Getopt::Mini;   # parses the @ARGV into %ARGV
    say YAML::Dump \%ARGV;
    ---
    h: 1
    file:
      - foo
      - bar

    # single flags like -h are checked with exists:

    say 'help...' if exists $ARGV{'h'};

    # barewords are pushed into the key '_'

    perl myprog.pl file1.c file2.c
    say "file: $_" for @{ $ARGV{''} };

Or you can just use a modular version:

    use Getopt::Mini later=>1; # nothing happens

    getopt;   #  imports into %ARGV
    my %argv = getopt;   #  imports into %argv instead

=head3 array mode

There's also a special mode that can be set with C<array => 1> that will
make a flag consume all following barewords:

    perl myprog.pl -a -b --files f1.txt f2.txt
    use Getopt::Mini array => 1;
    say YAML::Dump \%ARGV;
    ---
    h: ~
    file:
      - foo
      - bar

=head1 BUGS

This is *ALPHA* software. And despite its small footprint,
this is lurking with nasty bugs and potential api changes.

Complaints should be filed to the Getopt Foundation, which
has been treating severe NIH syndrome since 1980.

=head1 SEE ALSO

L<Getopt::Whatever> - no declarative spec like this module,
but the options in %ARGV and @ARGV are not where I expect them
to be.

L<Getopt::Casual> - similar to this module, but very keen on
turning entries into single param options.

=head1 AUTHOR

Rodrigo de Oliveira <rodrigolive@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Rodrigo de Oliveira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rodrigo de Oliveira <rodrigolive@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rodrigo de Oliveira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
