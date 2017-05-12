package Getopt::Usaginator;
BEGIN {
  $Getopt::Usaginator::VERSION = '0.0012';
}
# ABSTRACT: Conjure up a usage function for your applications


use strict;
use warnings;

use Package::Pkg;

sub import {
    my $package = caller;
    my $self = shift;

    if ( @_ ) {
        my @arguments = ( as => "${package}::usage" );
        if ( 1 == @_ )  { push @arguments, usage => $_[0] }
        else            { push @arguments, @_ }
        $self->usaginator( @arguments );
    }
}

sub _is_status ($) {
    return defined $_[0] && $_[0] =~ m/^\-?\d+$/;
}

sub _print ($$$) {
    my ( $logger, $target, $context ) = @_;

    if ( ref $target eq 'CODE' ) {
        $target->( @$context );
        return;
    }

    chomp $target if $target && ! ref $target;
    $target .= "\n";

    if ( ref $logger eq 'CODE' ) {
        $logger->( $target, @$context );
        return;
    }

    if ( ! ref $logger ) {
        s/^\s*//, s/\s*$// for $logger;
        $logger = lc $logger;

        if      ( $logger eq 'warn' )   { warn $target }
        elsif   ( $logger eq 'stdout' ) { print STDOUT $target }
        elsif   ( $logger eq 'stderr' ) { print STDERR $target }
        else                            { die "Invalid print mechanism ($logger)" }
    }
    elsif ( ref $logger eq 'GLOB' || UNIVERSAL::isa( $logger, 'IO::Handle' ) ) {
        print $logger $target;
    }
    else {
        die "Invalid print mechanism ($logger)";
    }
}

sub usaginator {
    my $self = shift;

    my ( $print, $error, $usage, $as );
    if ( @_ == 1 ) {
        $usage = $_[0]
    }
    else {
        my %given = @_;
        ( $print, $error, $usage, $as ) = @given{qw/ print error usage as /}
    }

    $print = 'warn' unless defined $print;

    my $code = sub {
        my ( $status, $error );
        if ( @_ > 1 )   { ( $status, $error ) = @_ }
        else            { $error = shift }

        if ( defined $error ) {
            if ( $error ) {
                if ( ! defined $status && _is_status $error )
                                            { $status = $error }
                else                        { _print $print, $error, [ @_ ] }
                $status = -1 unless defined $status;
            }
        }
        $status = 0 unless defined $status;
        _print $print, $usage, [ @_ ];
        exit $status;
    };

    if ( $as ) {
        pkg->install( { code => $code, as => $as, _into => scalar caller } ); 
    }

    return $code;
}

1;

__END__
=pod

=head1 NAME

Getopt::Usaginator - Conjure up a usage function for your applications

=head1 VERSION

version 0.0012

=head1 SYNOPSIS

    use Getopt::Usaginator <<_END_;

        Usage: xyzzy <options>
    
        --derp          Derp derp derp         
        --durp          Durp durp durp
        -h, --help      This usage
        
    _END_

    # The 'usage' subroutine is now installed

    ...

    $options = parse_options( @ARGV ); # Not supplied by Usaginator

    usage if $options{help}; # Print usage and exit with status 0

    if ( ! $options{derp} ) {
        # Print warning and usage and exit with status -1
        usage "You should really derp";
    }
    
    if ( $options{durp} ) {
        # Print warning and usage and exit with status 2
        usage 2 => "--durp is not ready yet";
    }

    ...

    usage 3 # Print usage and exit with status 3

=head1 DESCRIPTION

Getopt::Usaginator is a tool for creating a handy usage subroutine for commandline applications

It does not do any option parsing, but is best paired with L<Getopt::Long> or any of the other myriad of option parsers

=head1 USAGE

=head2 use Getopt::Usaginator <usage>

Install a C<usage> subroutine configured with the <usage> text

=head2 $code = Getopt::Usaginator->usaginator( <usage> )

Return a subroutine configured with the <usage> text

=head2 ...

More advanced usage is possible, peek under the hood for more information

    perldoc -m Getopt::Usaginator

An example:

    use Getopt::Usaginator
        # Called with the error
        error => sub { ... },
        # Called when usage printing is needed
        usage => sub { ... },
        ...
    ;

=head1 An example with Getopt::Long parsing

    use Getopt::Usaginator ...

    sub run {
        my $self = shift;
        my @arguments = @_;
    
        usage 0 unless @arguments;

        my ( $help );
        {     
            local @ARGV = @arguments;                                  
            GetOptions(
                'help|h|?' => \$help,
            );
        }

        usage 0 if $help;

        ...
    }

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

