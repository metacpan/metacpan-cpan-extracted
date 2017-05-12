#!/usr/bin/perl

use strict;
use warnings;
use Carp;

use lib qw(lib t t/lib);

use Test::More;

BEGIN {
    eval "use Test::Exception;";

    if ($@) {
        plan skip_all => 'Test::Exception needed';
    } 
}

# data source for tests
my $runtime_class = 'Syntax::X';
my %subclasses  =   (
    'Parameters'                =>  qr{Missing parameters},
    'Parameters::None'          =>  qr{Missing all},
    'Parameters::Source'        =>  qr{Missing source},
    'Parameters::Wrong'         =>  {
            regex   =>  qr{Wrong value},
            params  =>  {
                parameter   =>  q(page),
                value       =>  q(esta/pagina/no/existe),
            }
        },
    'Engine'                    =>  qr{external engine},
    'Engine::Use'               =>  qr{Could not use the module},
    'Engine::Language'          =>  qr{Unsupported syntax of language},
    'Template'                  =>  qr{Not access to or not found template},
);

plan tests => (scalar keys %subclasses) + 1;

# test the package load 
my $class = 'IkiWiki::Plugin::syntax::X';
use_ok( $class );

foreach my $subclass (keys %subclasses) {
    my  $full_class = "${runtime_class}::${subclass}";
    my  ( $regex, $text, %params );

    # get the description from the class
    $text   =   $full_class . " - " . $full_class->description();
    %params =   ();

    # extract regex and fields from the tests hash
    if (ref $subclasses{$subclass} eq 'HASH') {
        $regex  =  $subclasses{$subclass}->{regex};
        %params =  exists $subclasses{$subclass}->{params} 
                    ?   %{ $subclasses{$subclass}->{params} }
                    :   ();
    }
    else {
        $regex  =  $subclasses{$subclass};
    }

    # raise the exception and check the results
    throws_ok { raise_exception( $full_class, %params ) } $regex, $text;
}

sub raise_exception {
    my  $class  =   shift;
    my  @params =   @_;

    $class->throw(@params);
}


