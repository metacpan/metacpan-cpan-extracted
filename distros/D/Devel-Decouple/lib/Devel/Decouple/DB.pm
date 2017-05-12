# $Id$
package Devel::Decouple::DB;
use base 'Devel::Decouple';

use strict;
use warnings;
use Carp;
use version; our $VERSION = qv(0.0.2);

# run the invoked code via the perl debugger...
sub DB::DB {

}

# this block will execute before the debugger exits
END {
    my $self = _build_special( $0 );
    print $self->report;
    exit;
}

sub _build_special{
    my $module = shift;
    my %params;
    
    # build the params hash
    $params{_DOCUMENT_} = $module;
    $params{_MODULES_}  = '_ALL_';
    $params{_DEFAULT_}  = '_PRESERVED_';
    
    # and an object
    my $self = bless {%params}, __PACKAGE__;
    $self->_build();
    
    return $self;
}

1; # return true
__END__

=head1 NAME

Devel::Decouple::DB - decouple code from imported functions

=head1 SYNOPSIS

This module is intended to facilitate the testing and refactoring of legacy Perl code.

To generate a simple report about a module's or script's use of imported functions you can use Devel::Decouple::DB via the debugger.
    
    perl -d:Decouple::DB myscript.pl
    

Then using the parent class L<Devel::Decouple>, perhaps in a test file, you can easily redefine any of the functions that were listed to decouple (redefine) the problematic dependencies.
    
    # for the given module automatically redefine all called
    # functions that were imported (as no-ops)
    
    my $DD = Devel::Decouple->new();
    $DD->decouple( 'Some::Module' );
    

=head1 DESCRIPTION

For a detailed description and rationale please see the documentation for L<< Devel::Decouple >>.


=head1 INTERFACE 

As noted above, the only interface to this module is the perl debugger.


=head1 CONFIGURATION AND ENVIRONMENT

Devel::Decouple requires no configuration files or environment variables.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to dev@namimedia.com.


