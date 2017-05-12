use strict;
use warnings;

package Locale::Simple::Scraper;
BEGIN {
  $Locale::Simple::Scraper::AUTHORITY = 'cpan:GETTY';
}
$Locale::Simple::Scraper::VERSION = '0.019';
# ABSTRACT: scraper to find translation tokens in a directory

use Exporter 'import';
use Getopt::Long;
use File::Find;
use Cwd;
use Locale::Simple;
use Data::Dumper;
use Locale::Simple::Scraper::Parser;

our @EXPORT = qw(scrape);

sub scrape {
    @ARGV = @_;

    $| = 1;

    # Supported filetypes:
    my $js_ext = "";    # Javascript
    my $pl_ext = "";    # Perl
    my $py_ext = "";    # Python
    my $tx_ext = "";    # Text::Xslate (Kolon or Metakolon)

    my @ignores;
    my @only;

    my $output = 'po';
    my ($md5, $no_line_numbers);

    GetOptions(
        "js=s"            => \$js_ext,
        "pl=s"            => \$pl_ext,
        "py=s"            => \$py_ext,
        "tx=s"            => \$tx_ext,
        "ignore=s"        => \@ignores,
        "only=s"          => \@only,
        "output=s"        => \$output,
        "md5"             => \$md5,
        "no_line_numbers" => \$no_line_numbers,
    );

    # could add Getopt::Long here for override

    my @js = split( ",", $js_ext );
    push @js, 'js';

    my @pl = split( ",", $pl_ext );
    push @pl, 'pl', 'pm', 't';

    my @tx = split( ",", $tx_ext );
    push @tx, 'tx';

    my @py = split( ",", $py_ext );
    push @py, 'py';

    # extension list
    my %e = (
        ( map { $_ => 'js' } @js ),
        ( map { $_ => 'pl' } @pl ),
        ( map { $_ => 'tx' } @tx ),
        ( map { $_ => 'py' } @py ),
    );

    # functions with count of locale simple with function of parameter
    #
    # 1 = msgid
    # 2 = msgid_plural
    # 3 = msgctxt
    # 4 = domain
    #
    my %f = (
        l    => [1],
        ln   => [ 1, 2 ],
        ld   => [ 4, 1 ],
        lp   => [ 3, 1 ],
        lnp  => [ 3, 1, 2 ],
        ldn  => [ 4, 1, 2 ],
        ldp  => [ 4, 3, 1 ],
        ldnp => [ 4, 3, 1, 2 ],
    );

    my %files;

    my $dir    = getcwd;
    my $re_dir = $dir;
    $re_dir =~ s/\./\\./g;

    finddepth(
        sub {
            my $filename        = $File::Find::name;
            my $stored_filename = $filename;
            if ( $md5 ) {
                eval {
                    require Digest::MD5;
                    Digest::MD5->import( 'md5_hex' );
                };
                die "This feature requires Digest::MD5" if $@;
                $stored_filename = md5_hex( $filename );
            }
            $filename =~ s/^$dir\///g;
            for ( @ignores ) {
                return if $filename =~ /$_/;
            }
            if ( @only ) {
                my $found = 0;
                for ( @only ) {
                    $found = 1 if $filename =~ /$_/;
                }
                return unless $found;
            }
            my @fileparts = split( '\.', $File::Find::name );
            my $ext = pop @fileparts;
            $files{$File::Find::name} = [ $ext, $filename, $stored_filename ] if grep { $ext eq $_ } keys %e;
        },
        $dir
    );

    my @found;
    for my $file ( sort keys %files ) {
        my ( $ext, $filename, $stored_filename ) = @{ $files{$file} };
        my $type = $e{$ext};
        print STDERR $type . " => " . $file . "\n";
        return if -l $file and not -e readlink( $file );
        my $parses = Locale::Simple::Scraper::Parser->new( type => $type )->from_file( $file );
        my @file_things = map {
            {
                %{ result_from_params( $_->{args}, $f{ $_->{func} } ) },
                  line => $_->{line},
                  file => $stored_filename,
                  type => $type,
            }
        } @{$parses};
        push @found, @file_things;
    }

    if ( $output eq 'po' ) {
        my %files;
        my %token;
        for ( @found ) {
            my $key .= defined $_->{domain}       ? '"' . $_->{domain} . '"'       : 'undef';
            $key    .= defined $_->{msgctxt}      ? '"' . $_->{msgctxt} . '"'      : 'undef';
            $key    .= defined $_->{msgid}        ? '"' . $_->{msgid} . '"'        : 'undef';
            $key    .= defined $_->{msgid_plural} ? '"' . $_->{msgid_plural} . '"' : 'undef';
            $token{$key} = $_ unless defined $token{$key};
            $files{$key} = [] unless defined $files{$key};
            push @{ $files{$key} }, $_->{file} . ':' . $_->{line};
        }
        for my $k ( sort { $a cmp $b } keys %files ) {
            print "\n";
            print "#: " . join( ' ', @{ $files{$k} } ) . "\n" if !$no_line_numbers;
            print "#, locale-simple-format";
            print " " . $token{$k}{domain} if defined $token{$k}{domain};
            print "\n";
            for ( qw( msgctxt msgid msgid_plural ) ) {
                print $_. ' "' . Locale::Simple::gettext_escape( $token{$k}{$_} ) . '"' . "\n"
                  if defined $token{$k}{$_};
            }
            my $plural_marker = $token{$k}{msgid_plural} ? "[0]" : "";
            print qq[msgstr$plural_marker ""\n];

        }
    }
    elsif ( $output eq 'perl' ) {
        print Dumper \@found;
    }
    elsif ( $output eq 'json' ) {
        eval {
            require JSON;
            JSON->import;
            print encode_json( \@found );
        } or do {
            die "You require the module JSON for this output";
        };
    }
    elsif ( $output eq 'yaml' ) {
        eval {
            require YAML;
            YAML->import;
            print Dump( \@found );
        } or do {
            die "You require the module YAML for this output";
        };
    }
}

sub parse_line {
    my ( $line, $type, $f, @results ) = @_;
    return if $line =~ /^\s*\#.*/;
    for ( keys %{$f} ) {
        my @args = @{ $f->{$_} };
        my $params = get_func_params( $_, $line );
        next if !$params;
        my $argc = scalar @args;
        my ( $remainder, @params ) = parse_params( $params, $type, $argc );
        if ( scalar @params == $argc ) {
            push @results, result_from_params( \@params, \@args ), parse_line( $remainder, $type, $f );
        }
    }
    return @results;
}

sub result_from_params {
    my ( $params, $args ) = @_;
    my %result;
    my $pos = 0;
    for ( @{$args} ) {
        $result{msgid}        = $params->[$pos] if $_ eq 1;
        $result{msgid_plural} = $params->[$pos] if $_ eq 2;
        $result{msgctxt}      = $params->[$pos] if $_ eq 3;
        $result{domain}       = $params->[$pos] if $_ eq 4;
        $pos++;
    }
    return \%result;
}

sub get_func_params {
    my ( $func, $line ) = @_;
    $line =~ /([^\w]|^)$func\((.*)/;
    return $2;
}

sub parse_params {
    my ( $params, $type, $argc ) = @_;
    my @chars = split( '', $params );
    my @args;
    my $arg         = "";
    my $q_state     = 0;    # 0 = code, 1 = qoute, 2 = double qoute
    my $comma_state = 1;
    while ( defined( my $c = shift @chars ) ) {
        next if $c =~ /\s/ and !$q_state;
        if ( $q_state ) {
            if ( $c eq '\\' ) {
                my $esc = shift @chars;
                if ( $esc eq "'" or $esc eq '"' or $esc eq '\\' ) {
                    $arg .= $esc;
                }
                else {
                    warn "Unknown escape char '" . $esc . "'";
                }
            }
            elsif ( ( $c eq "'" and $q_state == 1 ) or ( $c eq '"' and $q_state == 2 ) ) {
                $q_state     = 0;
                $comma_state = 0;
                push @args, $arg;
                $arg = "";
                last if scalar @args == $argc;
            }
            else {
                $arg .= $c;
            }
        }
        else {
            if ( $c eq "'" or $c eq '"' ) {
                die "quote found where comma expected: " . $params unless $comma_state;
                $q_state = $c eq "'" ? 1 : 2;
            }
            elsif ( $c eq ',' ) {
                die "comma found after comma in code: " . $params if $comma_state;
                $comma_state = 1;
            }
            elsif ( $type eq 'js' ) {
                last;
            }
            else {
                last;
            }
        }
    }
    return join( '', @chars ), @args;
}

1;

__END__

=pod

=head1 NAME

Locale::Simple::Scraper - scraper to find translation tokens in a directory

=head1 VERSION

version 0.019

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by DuckDuckGo, Inc. L<http://duckduckgo.com/>, Torsten Raudssus <torsten@raudss.us>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
