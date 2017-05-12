package Devel::InPackage;
BEGIN {
  $Devel::InPackage::VERSION = '0.01';
}
# ABSTRACT: scan a file for package declarations or determine which package a line belongs to
use strict;
use warnings;
use 5.010;

use Carp qw(confess);
use File::Slurp qw(read_file);
use Sub::Exporter -setup => {
    exports => ['in_package', 'scan'],
};

our $VERSION;

my $MODULE = qr/(?<package>[A-Za-z0-9:]+)/;

sub in_package {
    my %args = @_;
    # XXX: hope you don't want to know what package foo is in here:
    # package main;
    # { package Bar; <foo> }
    my $point = delete $args{line} || confess 'need line';

    my $result = 'main';
    my $cb = sub {
        my ($line, $package, %info) = @_;
        my $line_number = $info{line_number};
        if( $line_number >= $point ){
            $result = $package;
            return 0;
        }
        return 1;
    };

    scan( %args, callback => $cb);

    return $result;
}

sub scan {
    my %args = @_;

    my $program = $args{code} //
      ($args{file} && read_file($args{file})) //
        confess 'Need "file" or "code"';

    my $callback = $args{callback} // confess 'Need "callback"';

    # this is very crude, and makes incorrect assumptions about Perl
    # syntax
    my @state = ('main');
    my $line_no = 0;
    while( $program =~ /^(?<line>.+)$/mg ){
        my $line = $+{line};
        my $saved_line = $line;

        # skip comments
        $line =~ s/#(.+)$//;

        while( $line =~ /(?<token>(?:
                                 { |
                                 } |
                                 \bpackage \s+ $MODULE \s* ; |
                                 \b(?:class|role) \s+ $MODULE (.+)? { ))
                        /xg ){
            given($+{token}){
                when('{'){
                    push @state, $state[-1];
                }
                when('}'){
                    confess "Unmatched closing } at $line_no" unless @state > 0;
                    pop @state;
                }
                when(/(package|class|role) ($MODULE)/){
                    push @state, $+{package};
                }
            }
        }

        my $continue_scanning = $callback->( $line, $state[-1], line_number => ++$line_no );
        return if !$continue_scanning; # end early
    }

    return;
}

1;

__END__
=pod

=head1 NAME

Devel::InPackage - scan a file for package declarations or determine which package a line belongs to

=head1 VERSION

version 0.01

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

