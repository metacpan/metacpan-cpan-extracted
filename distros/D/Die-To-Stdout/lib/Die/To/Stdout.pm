package Die::To::Stdout;
use 5.008001;
use strict;
use warnings;
use utf8;
use Exporter;

our $VERSION = "0.04";
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ();
our $OPTS        = { banner => 1 };

sub _die_to_stdout {
    my ($exception) = @_;
    my ( $package, $filename, $lineno ) = caller;
    
    #<<< START: do not let perltidy touch this
    $exception =(defined $exception) ? $exception : '<UNDEF>';
    if ( $OPTS->{banner} ) {
        print '+-- DIED --------------------'   . "\n";
        print '| Package  : ' . $package        . "\n";
        print '| Filename : ' . $filename       . "\n";
        print '| Line     : ' . $lineno         . "\n";
        print '| Err      : ' . $exception      . "\n";
        print '+----------------------------'   . "\n";
    }
    else {
        print "$exception\n";
    }
    #>>> END: do not let perltidy touch this
    if (@_) {
        CORE::die(@_);
    } else {
        CORE::die;
    }
}

sub import {
    no warnings;    # Name "CORE::GLOBAL::die" used only once: possible typo
    my ( $class, $opts ) = @_;
    $OPTS = $opts if (ref $opts eq 'HASH');
    *CORE::GLOBAL::die = \&_die_to_stdout;
}

1;

__END__

=encoding utf-8

=head1 NAME

Die::To::Stdout - Make die() print the error to both STDOUT and SDERR, then die.

=head1 SYNOPSIS

This ...

    use Die::To::Stdout;
    die("An error has occured");
    
Will print out something like this to STDOUT, then die.    

    +-- DIED --------------------
    | Package  : main
    | Filename : ........
    | Line     : ........
    | Err      : An error has occured
    +----------------------------
  
This ...

    use Die::To::Stdout { banner => 0 };
    die("An error has occured");
  
Will print out something like this to STDOUT, then die.    
    
    An error has occured

=head1 DESCRIPTION

=head2 What?

This module when loaded will make die() print the error to both STDOUT and SDERR, then die.

=head2 Why?

You migth want to use this module in case when both STDOUT and STDERR of your Perl script is redirected to the file.
If this is the case, and the script dies, the error message might be located at the TOP of your log file. 

Alternative solution could be to switch-off caching, like this:

    $| = 1;

=head1 SEE ALSO
 
L<Die::Alive>

=head1 LICENSE

Copyright (C) Jan Herout.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Herout E<lt>jan.herout@gmail.comE<gt>

=cut

