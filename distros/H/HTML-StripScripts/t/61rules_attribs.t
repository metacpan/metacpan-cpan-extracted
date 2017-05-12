use strict;
use Test::More tests => 1372;

BEGIN {
     $^W = 1;
     eval "require Data::Dumper; import Data::Dumper";
     $@ and eval "sub Dumper {'Install Data::Dumper for detailed diagnostics'}";
}

use HTML::StripScripts;

my %attrs_def_al = my %attrs_def_def = my %attrs_img_al =
    my %attrs_img_def = ( 'undef'  => undef,
                          '0'      => 0,
                          '1'      => 1,
                          'string' => '^foo$',
                          'regex'  => qr/^foo$/,
                          'sub'    => \&img_def_callback
    );
$attrs_def_al{sub}  = \&def_al_callback;
$attrs_def_def{sub} = \&def_def_callback;
$attrs_img_al{sub}  = \&img_al_callback;

## test attribute rules with fallback to *
my @order = qw(undef 0 1 string regex sub);

my %results;
foreach my $img_tag ( 0, 1 ) {
    foreach my $def_tag ( 0, 1 ) {
        foreach my $img_al ( $img_tag ? @order : '' ) {
            foreach my $img_def ( $img_tag ? @order : '' ) {
                foreach my $def_al ( $def_tag ? @order : '' ) {
                    foreach my $def_def ( $def_tag ? @order : '' ) {
                        my %Rules;
                        my $test = '[img::';
                        if ($img_tag) {
                            $test .= "${img_al}:${img_def}]";
                            $Rules{img}{align} = $attrs_img_al{$img_al}
                                unless $img_al eq 'undef';
                            $Rules{img}{'*'} = $attrs_img_def{$img_def}
                                unless $img_def eq 'undef';
                        }
                        else {
                            $test .= 'none]';
                        }
                        $test .= '[*::';
                        if ($def_tag) {
                            $test .= "${def_al}:${def_def}]";
                            $Rules{'*'}{align} = $attrs_def_al{$def_al}
                                unless $def_al eq 'undef';
                            $Rules{'*'}{'*'} = $attrs_def_def{$def_def}
                                unless $def_def eq 'undef';
                        }
                        else {
                            $test .= 'none]';
                        }
                        test_attrs( $test, \%Rules, $results{$test} );
                    }
                }
            }
        }
    }
}

## test required attributes

test_attrs( 'required_ok',
            { img => { required => [qw(alt align)] } },
            '<img align="foo" alt="bar" /><h1 align="foo"></h1>' );

test_attrs( 'required_not_ok_1',
            { img => { required => [qw(title)] } },
            '<!--filtered--><h1 align="foo"></h1>'
);

test_attrs( 'required_not_ok_2',
            { img => { required => [qw(alt title)] } },
            '<!--filtered--><h1 align="foo"></h1>' );

#===================================
sub test_attrs {
#===================================
    my ( $test, $Rules, $result ) = @_;
    my $f = HTML::StripScripts->new( { Rules => $Rules } );

    $f->input_start_document;
    $f->input_start('<img align="foo" alt="bar" />');
    $f->input_start('<h1 align="foo">');
    $f->input_end('</h1>');
    $f->input_end_document;
    is( $f->filtered_document, $result, "$test" )
        or diag( Dumper( $Rules, $f->{_hssRules} ) );
}

#===================================
sub img_al_callback {
#===================================
    my ( $filter, $tag, $attr, $val, $sub ) = @_;
    $sub ||= 'img_al';
    return "[$sub : $tag : $attr : $val]";
}

sub img_def_callback { return img_al_callback( @_, 'img_def' ) }
sub def_al_callback  { return img_al_callback( @_, 'def_al' ) }
sub def_def_callback { return img_al_callback( @_, 'def_def' ) }

BEGIN {

    my $ia_ial = "[img_al : img : align : foo]";
    my $id_ial = "[img_def : img : align : foo]";
    my $id_iat = "[img_def : img : alt : bar]";
    my $da_ial = "[def_al : img : align : foo]";
    my $da_hal = "[def_al : h1 : align : foo]";
    my $dd_ial = "[def_def : img : align : foo]";
    my $dd_iat = "[def_def : img : alt : bar]";
    my $dd_hal = "[def_def : h1 : align : foo]";

    %results = (
        '[img::none][*::none]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::none][*::undef:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::none][*::undef:0]' => qq{<img /><h1></h1>},
        '[img::none][*::undef:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::none][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::undef:sub]' =>
            qq{<img align="${dd_ial}" alt="${dd_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::none][*::0:undef]'  => qq{<img alt="bar" /><h1></h1>},
        '[img::none][*::0:0]'      => qq{<img /><h1></h1>},
        '[img::none][*::0:1]'      => qq{<img alt="bar" /><h1></h1>},
        '[img::none][*::0:string]' => qq{<img /><h1></h1>},
        '[img::none][*::0:regex]'  => qq{<img /><h1></h1>},
        '[img::none][*::0:sub]'    => qq{<img alt="${dd_iat}" /><h1></h1>},

        '[img::none][*::1:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::none][*::1:0]' => qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::1:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::none][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::1:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::none][*::string:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::none][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::string:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::none][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::string:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::none][*::regex:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::none][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::regex:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::none][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::none][*::regex:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::none][*::sub:undef]' =>
            qq{<img align="${da_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::none][*::sub:0]' =>
            qq{<img align="${da_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::none][*::sub:1]' =>
            qq{<img align="${da_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::none][*::sub:string]' =>
            qq{<img align="${da_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::none][*::sub:regex]' =>
            qq{<img align="${da_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::none][*::sub:sub]' =>
            qq{<img align="${da_ial}" alt="${dd_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::undef:undef][*::none]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:0][*::none]' => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:1][*::none]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:string][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::none]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::0:undef][*::none]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:0][*::none]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:1][*::none]' => qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:string][*::none]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::none]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:sub][*::none]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::1:undef][*::none]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:0][*::none]' => qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:1][*::none]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:string][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:sub][*::none]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::string:undef][*::none]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:0][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:1][*::none]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:string][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:sub][*::none]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::regex:undef][*::none]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:0][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:1][*::none]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:string][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::none]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::none]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::sub:undef][*::none]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:0][*::none]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:1][*::none]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:string][*::none]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::none]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::none]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::undef:undef][*::undef:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::undef:0]' => qq{<img /><h1></h1>},
        '[img::undef:undef][*::undef:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::undef:sub]' =>
            qq{<img align="${dd_ial}" alt="${dd_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::undef:undef][*::0:undef]'  => qq{<img alt="bar" /><h1></h1>},
        '[img::undef:undef][*::0:0]'      => qq{<img /><h1></h1>},
        '[img::undef:undef][*::0:1]'      => qq{<img alt="bar" /><h1></h1>},
        '[img::undef:undef][*::0:string]' => qq{<img /><h1></h1>},
        '[img::undef:undef][*::0:regex]'  => qq{<img /><h1></h1>},
        '[img::undef:undef][*::0:sub]' =>
            qq{<img alt="${dd_iat}" /><h1></h1>},

        '[img::undef:undef][*::1:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::1:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::1:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::undef:undef][*::string:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::string:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::string:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::undef:undef][*::regex:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::regex:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:undef][*::regex:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::undef:undef][*::sub:undef]' =>
            qq{<img align="${da_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::undef:undef][*::sub:0]' =>
            qq{<img align="${da_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::undef:undef][*::sub:1]' =>
            qq{<img align="${da_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::undef:undef][*::sub:string]' =>
            qq{<img align="${da_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::undef:undef][*::sub:regex]' =>
            qq{<img align="${da_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::undef:undef][*::sub:sub]' =>
            qq{<img align="${da_ial}" alt="${dd_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::undef:0][*::undef:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::undef:0]'      => qq{<img /><h1></h1>},
        '[img::undef:0][*::undef:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::undef:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::undef:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::undef:sub]' =>
            qq{<img /><h1 align="${dd_hal}"></h1>},

        '[img::undef:0][*::0:undef]'  => qq{<img /><h1></h1>},
        '[img::undef:0][*::0:0]'      => qq{<img /><h1></h1>},
        '[img::undef:0][*::0:1]'      => qq{<img /><h1></h1>},
        '[img::undef:0][*::0:string]' => qq{<img /><h1></h1>},
        '[img::undef:0][*::0:regex]'  => qq{<img /><h1></h1>},
        '[img::undef:0][*::0:sub]'    => qq{<img /><h1></h1>},

        '[img::undef:0][*::1:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::1:0]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::1:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::1:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::1:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::1:sub]'    => qq{<img /><h1 align="foo"></h1>},

        '[img::undef:0][*::string:undef]' => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::string:0]'     => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::string:1]'     => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::string:string]' =>
            qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::string:regex]' => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::string:sub]'   => qq{<img /><h1 align="foo"></h1>},

        '[img::undef:0][*::regex:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::regex:0]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::regex:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::regex:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::regex:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::undef:0][*::regex:sub]'    => qq{<img /><h1 align="foo"></h1>},

        '[img::undef:0][*::sub:undef]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::undef:0][*::sub:0]' => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::undef:0][*::sub:1]' => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::undef:0][*::sub:string]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::undef:0][*::sub:regex]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::undef:0][*::sub:sub]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},

        '[img::undef:1][*::undef:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::undef:0]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::undef:1][*::undef:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::undef:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::undef:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::undef:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${dd_hal}"></h1>},

        '[img::undef:1][*::0:undef]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::undef:1][*::0:0]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::undef:1][*::0:1]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::undef:1][*::0:string]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::undef:1][*::0:regex]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::undef:1][*::0:sub]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},

        '[img::undef:1][*::1:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::1:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::1:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::1:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::1:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::1:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::undef:1][*::string:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::string:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::string:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::string:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::string:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::string:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::undef:1][*::regex:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::regex:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::regex:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::regex:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::regex:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::regex:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::undef:1][*::sub:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},

        '[img::undef:1][*::sub:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::undef:1][*::sub:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::undef:1][*::sub:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::undef:1][*::sub:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::undef:1][*::sub:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},

        '[img::undef:string][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::undef:string][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::undef:string][*::0:undef]' => qq{<img align="foo" /><h1></h1>},
        '[img::undef:string][*::0:0]'     => qq{<img align="foo" /><h1></h1>},
        '[img::undef:string][*::0:1]'     => qq{<img align="foo" /><h1></h1>},
        '[img::undef:string][*::0:string]' =>
            qq{<img align="foo" /><h1></h1>},
        '[img::undef:string][*::0:regex]' => qq{<img align="foo" /><h1></h1>},
        '[img::undef:string][*::0:sub]'   => qq{<img align="foo" /><h1></h1>},

        '[img::undef:string][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::undef:string][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::undef:string][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:string][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::undef:string][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:string][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:string][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:string][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:string][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:string][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::undef:regex][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::undef:regex][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::undef:regex][*::0:undef]'  => qq{<img align="foo" /><h1></h1>},
        '[img::undef:regex][*::0:0]'      => qq{<img align="foo" /><h1></h1>},
        '[img::undef:regex][*::0:1]'      => qq{<img align="foo" /><h1></h1>},
        '[img::undef:regex][*::0:string]' => qq{<img align="foo" /><h1></h1>},
        '[img::undef:regex][*::0:regex]'  => qq{<img align="foo" /><h1></h1>},
        '[img::undef:regex][*::0:sub]'    => qq{<img align="foo" /><h1></h1>},

        '[img::undef:regex][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::undef:regex][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::undef:regex][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::undef:regex][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::undef:regex][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:regex][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:regex][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:regex][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:regex][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::undef:regex][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::undef:sub][*::undef:undef]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::undef:0]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::undef:sub][*::undef:1]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::undef:string]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::undef:regex]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::undef:sub]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::undef:sub][*::0:undef]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::undef:sub][*::0:0]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::undef:sub][*::0:1]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::undef:sub][*::0:string]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::undef:sub][*::0:regex]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::undef:sub][*::0:sub]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1></h1>},

        '[img::undef:sub][*::1:undef]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::1:0]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::1:1]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::1:string]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::1:regex]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::1:sub]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::undef:sub][*::string:undef]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::string:0]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::string:1]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::string:string]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::string:regex]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::string:sub]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::undef:sub][*::regex:undef]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::regex:0]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::regex:1]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::regex:string]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::regex:regex]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::undef:sub][*::regex:sub]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::undef:sub][*::sub:undef]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::undef:sub][*::sub:0]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::undef:sub][*::sub:1]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::undef:sub][*::sub:string]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::undef:sub][*::sub:regex]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::undef:sub][*::sub:sub]' =>
            qq{<img align="${id_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::0:undef][*::undef:undef]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:undef][*::undef:0]' => qq{<img /><h1></h1>},
        '[img::0:undef][*::undef:1]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:undef][*::undef:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::undef:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::undef:sub]' =>
            qq{<img alt="${dd_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::0:undef][*::0:undef]'  => qq{<img alt="bar" /><h1></h1>},
        '[img::0:undef][*::0:0]'      => qq{<img /><h1></h1>},
        '[img::0:undef][*::0:1]'      => qq{<img alt="bar" /><h1></h1>},
        '[img::0:undef][*::0:string]' => qq{<img /><h1></h1>},
        '[img::0:undef][*::0:regex]'  => qq{<img /><h1></h1>},
        '[img::0:undef][*::0:sub]'    => qq{<img alt="${dd_iat}" /><h1></h1>},

        '[img::0:undef][*::1:undef]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:undef][*::1:0]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::1:1]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:undef][*::1:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::1:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::1:sub]' =>
            qq{<img alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::0:undef][*::string:undef]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:undef][*::string:0]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::string:1]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:undef][*::string:string]' =>
            qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::string:regex]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::string:sub]' =>
            qq{<img alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::0:undef][*::regex:undef]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:undef][*::regex:0]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::regex:1]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:undef][*::regex:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::regex:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:undef][*::regex:sub]' =>
            qq{<img alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::0:undef][*::sub:undef]' =>
            qq{<img alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::0:undef][*::sub:0]' => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:undef][*::sub:1]' =>
            qq{<img alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::0:undef][*::sub:string]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:undef][*::sub:regex]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:undef][*::sub:sub]' =>
            qq{<img alt="${dd_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::0:0][*::undef:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::undef:0]'      => qq{<img /><h1></h1>},
        '[img::0:0][*::undef:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::undef:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::undef:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::undef:sub]' => qq{<img /><h1 align="${dd_hal}"></h1>},

        '[img::0:0][*::0:undef]'  => qq{<img /><h1></h1>},
        '[img::0:0][*::0:0]'      => qq{<img /><h1></h1>},
        '[img::0:0][*::0:1]'      => qq{<img /><h1></h1>},
        '[img::0:0][*::0:string]' => qq{<img /><h1></h1>},
        '[img::0:0][*::0:regex]'  => qq{<img /><h1></h1>},
        '[img::0:0][*::0:sub]'    => qq{<img /><h1></h1>},

        '[img::0:0][*::1:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::1:0]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::1:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::1:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::1:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::1:sub]'    => qq{<img /><h1 align="foo"></h1>},

        '[img::0:0][*::string:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::string:0]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::string:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::string:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::string:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::string:sub]'    => qq{<img /><h1 align="foo"></h1>},

        '[img::0:0][*::regex:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::regex:0]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::regex:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::regex:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::regex:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:0][*::regex:sub]'    => qq{<img /><h1 align="foo"></h1>},

        '[img::0:0][*::sub:undef]'  => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:0][*::sub:0]'      => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:0][*::sub:1]'      => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:0][*::sub:string]' => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:0][*::sub:regex]'  => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:0][*::sub:sub]'    => qq{<img /><h1 align="${da_hal}"></h1>},

        '[img::0:1][*::undef:undef]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::undef:0]' => qq{<img alt="bar" /><h1></h1>},
        '[img::0:1][*::undef:1]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::undef:string]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::undef:regex]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::undef:sub]' =>
            qq{<img alt="bar" /><h1 align="${dd_hal}"></h1>},

        '[img::0:1][*::0:undef]'  => qq{<img alt="bar" /><h1></h1>},
        '[img::0:1][*::0:0]'      => qq{<img alt="bar" /><h1></h1>},
        '[img::0:1][*::0:1]'      => qq{<img alt="bar" /><h1></h1>},
        '[img::0:1][*::0:string]' => qq{<img alt="bar" /><h1></h1>},
        '[img::0:1][*::0:regex]'  => qq{<img alt="bar" /><h1></h1>},
        '[img::0:1][*::0:sub]'    => qq{<img alt="bar" /><h1></h1>},

        '[img::0:1][*::1:undef]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::1:0]' => qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::1:1]' => qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::1:string]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::1:regex]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::1:sub]' => qq{<img alt="bar" /><h1 align="foo"></h1>},

        '[img::0:1][*::string:undef]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::string:0]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::string:1]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::string:string]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::string:regex]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::string:sub]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},

        '[img::0:1][*::regex:undef]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::regex:0]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::regex:1]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::regex:string]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::regex:regex]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},
        '[img::0:1][*::regex:sub]' =>
            qq{<img alt="bar" /><h1 align="foo"></h1>},

        '[img::0:1][*::sub:undef]' =>
            qq{<img alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::0:1][*::sub:0]' =>
            qq{<img alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::0:1][*::sub:1]' =>
            qq{<img alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::0:1][*::sub:string]' =>
            qq{<img alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::0:1][*::sub:regex]' =>
            qq{<img alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::0:1][*::sub:sub]' =>
            qq{<img alt="bar" /><h1 align="${da_hal}"></h1>},

        '[img::0:string][*::undef:undef]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::undef:0]'     => qq{<img /><h1></h1>},
        '[img::0:string][*::undef:1]'     => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::undef:string]' =>
            qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::undef:regex]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::undef:sub]' =>
            qq{<img /><h1 align="${dd_hal}"></h1>},

        '[img::0:string][*::0:undef]'  => qq{<img /><h1></h1>},
        '[img::0:string][*::0:0]'      => qq{<img /><h1></h1>},
        '[img::0:string][*::0:1]'      => qq{<img /><h1></h1>},
        '[img::0:string][*::0:string]' => qq{<img /><h1></h1>},
        '[img::0:string][*::0:regex]'  => qq{<img /><h1></h1>},
        '[img::0:string][*::0:sub]'    => qq{<img /><h1></h1>},

        '[img::0:string][*::1:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::1:0]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::1:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::1:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::1:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::1:sub]'    => qq{<img /><h1 align="foo"></h1>},

        '[img::0:string][*::string:undef]' =>
            qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::string:0]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::string:1]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::string:string]' =>
            qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::string:regex]' =>
            qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::string:sub]' => qq{<img /><h1 align="foo"></h1>},

        '[img::0:string][*::regex:undef]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::regex:0]'     => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::regex:1]'     => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::regex:string]' =>
            qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::regex:regex]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:string][*::regex:sub]'   => qq{<img /><h1 align="foo"></h1>},

        '[img::0:string][*::sub:undef]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:string][*::sub:0]' => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:string][*::sub:1]' => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:string][*::sub:string]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:string][*::sub:regex]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:string][*::sub:sub]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},

        '[img::0:regex][*::undef:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::undef:0]'      => qq{<img /><h1></h1>},
        '[img::0:regex][*::undef:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::undef:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::undef:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::undef:sub]' =>
            qq{<img /><h1 align="${dd_hal}"></h1>},

        '[img::0:regex][*::0:undef]'  => qq{<img /><h1></h1>},
        '[img::0:regex][*::0:0]'      => qq{<img /><h1></h1>},
        '[img::0:regex][*::0:1]'      => qq{<img /><h1></h1>},
        '[img::0:regex][*::0:string]' => qq{<img /><h1></h1>},
        '[img::0:regex][*::0:regex]'  => qq{<img /><h1></h1>},
        '[img::0:regex][*::0:sub]'    => qq{<img /><h1></h1>},

        '[img::0:regex][*::1:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::1:0]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::1:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::1:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::1:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::1:sub]'    => qq{<img /><h1 align="foo"></h1>},

        '[img::0:regex][*::string:undef]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::string:0]'     => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::string:1]'     => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::string:string]' =>
            qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::string:regex]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::string:sub]'   => qq{<img /><h1 align="foo"></h1>},

        '[img::0:regex][*::regex:undef]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::regex:0]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::regex:1]'      => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::regex:string]' => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::regex:regex]'  => qq{<img /><h1 align="foo"></h1>},
        '[img::0:regex][*::regex:sub]'    => qq{<img /><h1 align="foo"></h1>},

        '[img::0:regex][*::sub:undef]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:regex][*::sub:0]' => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:regex][*::sub:1]' => qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:regex][*::sub:string]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:regex][*::sub:regex]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},
        '[img::0:regex][*::sub:sub]' =>
            qq{<img /><h1 align="${da_hal}"></h1>},

        '[img::0:sub][*::undef:undef]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::undef:0]' => qq{<img alt="${id_iat}" /><h1></h1>},
        '[img::0:sub][*::undef:1]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::undef:string]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::undef:regex]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::undef:sub]' =>
            qq{<img alt="${id_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::0:sub][*::0:undef]'  => qq{<img alt="${id_iat}" /><h1></h1>},
        '[img::0:sub][*::0:0]'      => qq{<img alt="${id_iat}" /><h1></h1>},
        '[img::0:sub][*::0:1]'      => qq{<img alt="${id_iat}" /><h1></h1>},
        '[img::0:sub][*::0:string]' => qq{<img alt="${id_iat}" /><h1></h1>},
        '[img::0:sub][*::0:regex]'  => qq{<img alt="${id_iat}" /><h1></h1>},
        '[img::0:sub][*::0:sub]'    => qq{<img alt="${id_iat}" /><h1></h1>},

        '[img::0:sub][*::1:undef]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::1:0]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::1:1]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::1:string]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::1:regex]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::1:sub]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::0:sub][*::string:undef]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::string:0]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::string:1]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::string:string]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::string:regex]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::string:sub]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::0:sub][*::regex:undef]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::regex:0]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::regex:1]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::regex:string]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::regex:regex]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::0:sub][*::regex:sub]' =>
            qq{<img alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::0:sub][*::sub:undef]' =>
            qq{<img alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::0:sub][*::sub:0]' =>
            qq{<img alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::0:sub][*::sub:1]' =>
            qq{<img alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::0:sub][*::sub:string]' =>
            qq{<img alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::0:sub][*::sub:regex]' =>
            qq{<img alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::0:sub][*::sub:sub]' =>
            qq{<img alt="${id_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::1:undef][*::undef:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:undef][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::1:undef][*::undef:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:undef][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::undef:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::1:undef][*::0:undef]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::1:undef][*::0:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::1:undef][*::0:1]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::1:undef][*::0:string]' => qq{<img align="foo" /><h1></h1>},
        '[img::1:undef][*::0:regex]'  => qq{<img align="foo" /><h1></h1>},
        '[img::1:undef][*::0:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1></h1>},

        '[img::1:undef][*::1:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:undef][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::1:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:undef][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::1:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::1:undef][*::string:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:undef][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::string:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:undef][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::string:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::1:undef][*::regex:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:undef][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::regex:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:undef][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:undef][*::regex:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::1:undef][*::sub:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::1:undef][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:undef][*::sub:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::1:undef][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:undef][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:undef][*::sub:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::1:0][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::1:0][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::1:0][*::0:undef]'  => qq{<img align="foo" /><h1></h1>},
        '[img::1:0][*::0:0]'      => qq{<img align="foo" /><h1></h1>},
        '[img::1:0][*::0:1]'      => qq{<img align="foo" /><h1></h1>},
        '[img::1:0][*::0:string]' => qq{<img align="foo" /><h1></h1>},
        '[img::1:0][*::0:regex]'  => qq{<img align="foo" /><h1></h1>},
        '[img::1:0][*::0:sub]'    => qq{<img align="foo" /><h1></h1>},

        '[img::1:0][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::1:0]' => qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::1:1]' => qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::1:0][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::1:0][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:0][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::1:0][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:0][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:0][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:0][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:0][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:0][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::1:1][*::undef:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::undef:0]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::1:1][*::undef:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::undef:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::undef:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::undef:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${dd_hal}"></h1>},

        '[img::1:1][*::0:undef]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::1:1][*::0:0]' => qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::1:1][*::0:1]' => qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::1:1][*::0:string]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::1:1][*::0:regex]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::1:1][*::0:sub]' => qq{<img align="foo" alt="bar" /><h1></h1>},

        '[img::1:1][*::1:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::1:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::1:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::1:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::1:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::1:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::1:1][*::string:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::string:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::string:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::string:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::string:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::string:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::1:1][*::regex:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::regex:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::regex:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::regex:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::regex:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::1:1][*::regex:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::1:1][*::sub:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::1:1][*::sub:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::1:1][*::sub:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::1:1][*::sub:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::1:1][*::sub:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::1:1][*::sub:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},

        '[img::1:string][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::1:string][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::1:string][*::0:undef]'  => qq{<img align="foo" /><h1></h1>},
        '[img::1:string][*::0:0]'      => qq{<img align="foo" /><h1></h1>},
        '[img::1:string][*::0:1]'      => qq{<img align="foo" /><h1></h1>},
        '[img::1:string][*::0:string]' => qq{<img align="foo" /><h1></h1>},
        '[img::1:string][*::0:regex]'  => qq{<img align="foo" /><h1></h1>},
        '[img::1:string][*::0:sub]'    => qq{<img align="foo" /><h1></h1>},

        '[img::1:string][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::1:string][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::1:string][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:string][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::1:string][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:string][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:string][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:string][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:string][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:string][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::1:regex][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::1:regex][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::1:regex][*::0:undef]'  => qq{<img align="foo" /><h1></h1>},
        '[img::1:regex][*::0:0]'      => qq{<img align="foo" /><h1></h1>},
        '[img::1:regex][*::0:1]'      => qq{<img align="foo" /><h1></h1>},
        '[img::1:regex][*::0:string]' => qq{<img align="foo" /><h1></h1>},
        '[img::1:regex][*::0:regex]'  => qq{<img align="foo" /><h1></h1>},
        '[img::1:regex][*::0:sub]'    => qq{<img align="foo" /><h1></h1>},

        '[img::1:regex][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::1:regex][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::1:regex][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::1:regex][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::1:regex][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:regex][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:regex][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:regex][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:regex][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::1:regex][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::1:sub][*::undef:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::undef:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::1:sub][*::undef:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::undef:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::undef:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::undef:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::1:sub][*::0:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::1:sub][*::0:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::1:sub][*::0:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::1:sub][*::0:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::1:sub][*::0:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::1:sub][*::0:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},

        '[img::1:sub][*::1:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::1:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::1:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::1:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::1:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::1:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::1:sub][*::string:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::string:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::string:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::string:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::string:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::string:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::1:sub][*::regex:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::regex:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::regex:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::regex:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::regex:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::1:sub][*::regex:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::1:sub][*::sub:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::1:sub][*::sub:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::1:sub][*::sub:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::1:sub][*::sub:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::1:sub][*::sub:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::1:sub][*::sub:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::string:undef][*::undef:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:undef][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:undef][*::undef:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:undef][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::undef:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::string:undef][*::0:undef]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::string:undef][*::0:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:undef][*::0:1]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::string:undef][*::0:string]' =>
            qq{<img align="foo" /><h1></h1>},
        '[img::string:undef][*::0:regex]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:undef][*::0:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1></h1>},

        '[img::string:undef][*::1:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:undef][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::1:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:undef][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::1:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::string:undef][*::string:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:undef][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::string:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:undef][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::string:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::string:undef][*::regex:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:undef][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::regex:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:undef][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:undef][*::regex:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::string:undef][*::sub:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::string:undef][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:undef][*::sub:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::string:undef][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:undef][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:undef][*::sub:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::string:0][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:0][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::string:0][*::0:undef]'  => qq{<img align="foo" /><h1></h1>},
        '[img::string:0][*::0:0]'      => qq{<img align="foo" /><h1></h1>},
        '[img::string:0][*::0:1]'      => qq{<img align="foo" /><h1></h1>},
        '[img::string:0][*::0:string]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:0][*::0:regex]'  => qq{<img align="foo" /><h1></h1>},
        '[img::string:0][*::0:sub]'    => qq{<img align="foo" /><h1></h1>},

        '[img::string:0][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::string:0][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::string:0][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:0][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::string:0][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:0][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:0][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:0][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:0][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:0][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::string:1][*::undef:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::undef:0]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::string:1][*::undef:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::undef:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::undef:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::undef:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${dd_hal}"></h1>},

        '[img::string:1][*::0:undef]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::string:1][*::0:0]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::string:1][*::0:1]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::string:1][*::0:string]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::string:1][*::0:regex]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::string:1][*::0:sub]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},

        '[img::string:1][*::1:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::1:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::1:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::1:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::1:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::1:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::string:1][*::string:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::string:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::string:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::string:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::string:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::string:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::string:1][*::regex:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::regex:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::regex:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::regex:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::regex:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::string:1][*::regex:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::string:1][*::sub:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::string:1][*::sub:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::string:1][*::sub:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::string:1][*::sub:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::string:1][*::sub:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::string:1][*::sub:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},

        '[img::string:string][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::undef:0]' =>
            qq{<img align="foo" /><h1></h1>},
        '[img::string:string][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::string:string][*::0:undef]' =>
            qq{<img align="foo" /><h1></h1>},
        '[img::string:string][*::0:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:string][*::0:1]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:string][*::0:string]' =>
            qq{<img align="foo" /><h1></h1>},
        '[img::string:string][*::0:regex]' =>
            qq{<img align="foo" /><h1></h1>},
        '[img::string:string][*::0:sub]' => qq{<img align="foo" /><h1></h1>},

        '[img::string:string][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::string:string][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::string:string][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:string][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::string:string][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:string][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:string][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:string][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:string][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:string][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::string:regex][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:regex][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::string:regex][*::0:undef]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:regex][*::0:0]'     => qq{<img align="foo" /><h1></h1>},
        '[img::string:regex][*::0:1]'     => qq{<img align="foo" /><h1></h1>},
        '[img::string:regex][*::0:string]' =>
            qq{<img align="foo" /><h1></h1>},
        '[img::string:regex][*::0:regex]' => qq{<img align="foo" /><h1></h1>},
        '[img::string:regex][*::0:sub]'   => qq{<img align="foo" /><h1></h1>},

        '[img::string:regex][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::string:regex][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::string:regex][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::string:regex][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::string:regex][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:regex][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:regex][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:regex][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:regex][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::string:regex][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::string:sub][*::undef:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::undef:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::string:sub][*::undef:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::undef:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::undef:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::undef:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::string:sub][*::0:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::string:sub][*::0:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::string:sub][*::0:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::string:sub][*::0:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::string:sub][*::0:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::string:sub][*::0:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},

        '[img::string:sub][*::1:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::1:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::1:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::1:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::1:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::1:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::string:sub][*::string:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::string:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::string:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::string:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::string:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::string:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::string:sub][*::regex:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::regex:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::regex:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::regex:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::regex:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::string:sub][*::regex:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::string:sub][*::sub:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::string:sub][*::sub:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::string:sub][*::sub:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::string:sub][*::sub:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::string:sub][*::sub:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::string:sub][*::sub:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::regex:undef][*::undef:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:undef][*::undef:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::undef:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::regex:undef][*::0:undef]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::regex:undef][*::0:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:undef][*::0:1]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::regex:undef][*::0:string]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:undef][*::0:regex]'  => qq{<img align="foo" /><h1></h1>},
        '[img::regex:undef][*::0:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1></h1>},

        '[img::regex:undef][*::1:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::1:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::1:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::regex:undef][*::string:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::string:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::string:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::regex:undef][*::regex:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::regex:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:undef][*::regex:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::regex:undef][*::sub:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::regex:undef][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:undef][*::sub:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::regex:undef][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:undef][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:undef][*::sub:sub]' =>
            qq{<img align="foo" alt="${dd_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::regex:0][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:0][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::regex:0][*::0:undef]'  => qq{<img align="foo" /><h1></h1>},
        '[img::regex:0][*::0:0]'      => qq{<img align="foo" /><h1></h1>},
        '[img::regex:0][*::0:1]'      => qq{<img align="foo" /><h1></h1>},
        '[img::regex:0][*::0:string]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:0][*::0:regex]'  => qq{<img align="foo" /><h1></h1>},
        '[img::regex:0][*::0:sub]'    => qq{<img align="foo" /><h1></h1>},

        '[img::regex:0][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::regex:0][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::regex:0][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:0][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::regex:0][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:0][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:0][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:0][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:0][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:0][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::regex:1][*::undef:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::undef:0]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::regex:1][*::undef:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::undef:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::undef:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::undef:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${dd_hal}"></h1>},

        '[img::regex:1][*::0:undef]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::regex:1][*::0:0]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::regex:1][*::0:1]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::regex:1][*::0:string]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::regex:1][*::0:regex]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},
        '[img::regex:1][*::0:sub]' =>
            qq{<img align="foo" alt="bar" /><h1></h1>},

        '[img::regex:1][*::1:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::1:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::1:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::1:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::1:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::1:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::regex:1][*::string:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::string:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::string:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::string:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::string:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::string:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::regex:1][*::regex:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::regex:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::regex:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::regex:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::regex:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},
        '[img::regex:1][*::regex:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="foo"></h1>},

        '[img::regex:1][*::sub:undef]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::regex:1][*::sub:0]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::regex:1][*::sub:1]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::regex:1][*::sub:string]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::regex:1][*::sub:regex]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::regex:1][*::sub:sub]' =>
            qq{<img align="foo" alt="bar" /><h1 align="${da_hal}"></h1>},

        '[img::regex:string][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:string][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::regex:string][*::0:undef]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:string][*::0:0]'     => qq{<img align="foo" /><h1></h1>},
        '[img::regex:string][*::0:1]'     => qq{<img align="foo" /><h1></h1>},
        '[img::regex:string][*::0:string]' =>
            qq{<img align="foo" /><h1></h1>},
        '[img::regex:string][*::0:regex]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:string][*::0:sub]'   => qq{<img align="foo" /><h1></h1>},

        '[img::regex:string][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::regex:string][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::regex:string][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:string][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::regex:string][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:string][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:string][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:string][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:string][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:string][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::regex:regex][*::undef:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::undef:0]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:regex][*::undef:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::undef:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::undef:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::undef:sub]' =>
            qq{<img align="foo" /><h1 align="${dd_hal}"></h1>},

        '[img::regex:regex][*::0:undef]'  => qq{<img align="foo" /><h1></h1>},
        '[img::regex:regex][*::0:0]'      => qq{<img align="foo" /><h1></h1>},
        '[img::regex:regex][*::0:1]'      => qq{<img align="foo" /><h1></h1>},
        '[img::regex:regex][*::0:string]' => qq{<img align="foo" /><h1></h1>},
        '[img::regex:regex][*::0:regex]'  => qq{<img align="foo" /><h1></h1>},
        '[img::regex:regex][*::0:sub]'    => qq{<img align="foo" /><h1></h1>},

        '[img::regex:regex][*::1:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::1:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::1:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::1:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::1:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::1:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::regex:regex][*::string:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::string:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::string:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::string:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::string:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::string:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::regex:regex][*::regex:undef]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::regex:0]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::regex:1]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::regex:string]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::regex:regex]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},
        '[img::regex:regex][*::regex:sub]' =>
            qq{<img align="foo" /><h1 align="foo"></h1>},

        '[img::regex:regex][*::sub:undef]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:regex][*::sub:0]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:regex][*::sub:1]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:regex][*::sub:string]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:regex][*::sub:regex]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},
        '[img::regex:regex][*::sub:sub]' =>
            qq{<img align="foo" /><h1 align="${da_hal}"></h1>},

        '[img::regex:sub][*::undef:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::undef:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::regex:sub][*::undef:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::undef:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::undef:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::undef:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::regex:sub][*::0:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::regex:sub][*::0:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::regex:sub][*::0:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::regex:sub][*::0:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::regex:sub][*::0:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},
        '[img::regex:sub][*::0:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1></h1>},

        '[img::regex:sub][*::1:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::1:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::1:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::1:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::1:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::1:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::regex:sub][*::string:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::string:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::string:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::string:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::string:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::string:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::regex:sub][*::regex:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::regex:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::regex:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::regex:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::regex:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::regex:sub][*::regex:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::regex:sub][*::sub:undef]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::regex:sub][*::sub:0]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::regex:sub][*::sub:1]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::regex:sub][*::sub:string]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::regex:sub][*::sub:regex]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::regex:sub][*::sub:sub]' =>
            qq{<img align="foo" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::sub:undef][*::undef:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::undef:0]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:undef][*::undef:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::undef:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::undef:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::undef:sub]' =>
            qq{<img align="${ia_ial}" alt="${dd_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::sub:undef][*::0:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1></h1>},
        '[img::sub:undef][*::0:0]' => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:undef][*::0:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1></h1>},
        '[img::sub:undef][*::0:string]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:undef][*::0:regex]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:undef][*::0:sub]' =>
            qq{<img align="${ia_ial}" alt="${dd_iat}" /><h1></h1>},

        '[img::sub:undef][*::1:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::1:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::1:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::1:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::1:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::1:sub]' =>
            qq{<img align="${ia_ial}" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::sub:undef][*::string:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::string:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::string:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::string:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::string:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::string:sub]' =>
            qq{<img align="${ia_ial}" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::sub:undef][*::regex:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::regex:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::regex:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::regex:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::regex:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:undef][*::regex:sub]' =>
            qq{<img align="${ia_ial}" alt="${dd_iat}" /><h1 align="foo"></h1>},

        '[img::sub:undef][*::sub:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::sub:undef][*::sub:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:undef][*::sub:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::sub:undef][*::sub:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:undef][*::sub:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:undef][*::sub:sub]' =>
            qq{<img align="${ia_ial}" alt="${dd_iat}" /><h1 align="${da_hal}"></h1>},

        '[img::sub:0][*::undef:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::undef:0]' => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:0][*::undef:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::undef:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::undef:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::undef:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="${dd_hal}"></h1>},

        '[img::sub:0][*::0:undef]'  => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:0][*::0:0]'      => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:0][*::0:1]'      => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:0][*::0:string]' => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:0][*::0:regex]'  => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:0][*::0:sub]'    => qq{<img align="${ia_ial}" /><h1></h1>},

        '[img::sub:0][*::1:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::1:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::1:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::1:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::1:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::1:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},

        '[img::sub:0][*::string:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::string:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::string:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::string:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::string:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::string:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},

        '[img::sub:0][*::regex:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::regex:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::regex:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::regex:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::regex:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:0][*::regex:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},

        '[img::sub:0][*::sub:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:0][*::sub:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:0][*::sub:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:0][*::sub:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:0][*::sub:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:0][*::sub:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},

        '[img::sub:1][*::undef:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::undef:0]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1></h1>},
        '[img::sub:1][*::undef:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::undef:string]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::undef:regex]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::undef:sub]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="${dd_hal}"></h1>},

        '[img::sub:1][*::0:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1></h1>},
        '[img::sub:1][*::0:0]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1></h1>},
        '[img::sub:1][*::0:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1></h1>},
        '[img::sub:1][*::0:string]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1></h1>},
        '[img::sub:1][*::0:regex]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1></h1>},
        '[img::sub:1][*::0:sub]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1></h1>},

        '[img::sub:1][*::1:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::1:0]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::1:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::1:string]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::1:regex]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::1:sub]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},

        '[img::sub:1][*::string:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::string:0]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::string:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::string:string]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::string:regex]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::string:sub]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},

        '[img::sub:1][*::regex:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::regex:0]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::regex:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::regex:string]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::regex:regex]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},
        '[img::sub:1][*::regex:sub]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="foo"></h1>},

        '[img::sub:1][*::sub:undef]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::sub:1][*::sub:0]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::sub:1][*::sub:1]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::sub:1][*::sub:string]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::sub:1][*::sub:regex]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},
        '[img::sub:1][*::sub:sub]' =>
            qq{<img align="${ia_ial}" alt="bar" /><h1 align="${da_hal}"></h1>},

        '[img::sub:string][*::undef:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::undef:0]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:string][*::undef:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::undef:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::undef:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::undef:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="${dd_hal}"></h1>},

        '[img::sub:string][*::0:undef]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:string][*::0:0]' => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:string][*::0:1]' => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:string][*::0:string]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:string][*::0:regex]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:string][*::0:sub]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},

        '[img::sub:string][*::1:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::1:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::1:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::1:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::1:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::1:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},

        '[img::sub:string][*::string:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::string:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::string:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::string:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::string:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::string:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},

        '[img::sub:string][*::regex:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::regex:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::regex:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::regex:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::regex:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:string][*::regex:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},

        '[img::sub:string][*::sub:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:string][*::sub:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:string][*::sub:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:string][*::sub:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:string][*::sub:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:string][*::sub:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},

        '[img::sub:regex][*::undef:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::undef:0]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:regex][*::undef:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::undef:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::undef:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::undef:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="${dd_hal}"></h1>},

        '[img::sub:regex][*::0:undef]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:regex][*::0:0]' => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:regex][*::0:1]' => qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:regex][*::0:string]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:regex][*::0:regex]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},
        '[img::sub:regex][*::0:sub]' =>
            qq{<img align="${ia_ial}" /><h1></h1>},

        '[img::sub:regex][*::1:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::1:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::1:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::1:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::1:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::1:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},

        '[img::sub:regex][*::string:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::string:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::string:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::string:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::string:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::string:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},

        '[img::sub:regex][*::regex:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::regex:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::regex:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::regex:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::regex:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},
        '[img::sub:regex][*::regex:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="foo"></h1>},

        '[img::sub:regex][*::sub:undef]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:regex][*::sub:0]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:regex][*::sub:1]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:regex][*::sub:string]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:regex][*::sub:regex]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:regex][*::sub:sub]' =>
            qq{<img align="${ia_ial}" /><h1 align="${da_hal}"></h1>},

        '[img::sub:sub][*::undef:undef]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::undef:0]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::sub:sub][*::undef:1]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::undef:string]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::undef:regex]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::undef:sub]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="${dd_hal}"></h1>},

        '[img::sub:sub][*::0:undef]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::sub:sub][*::0:0]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::sub:sub][*::0:1]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::sub:sub][*::0:string]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::sub:sub][*::0:regex]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1></h1>},
        '[img::sub:sub][*::0:sub]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1></h1>},

        '[img::sub:sub][*::1:undef]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::1:0]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::1:1]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::1:string]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::1:regex]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::1:sub]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::sub:sub][*::string:undef]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::string:0]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::string:1]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::string:string]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::string:regex]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::string:sub]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::sub:sub][*::regex:undef]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::regex:0]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::regex:1]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::regex:string]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::regex:regex]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},
        '[img::sub:sub][*::regex:sub]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="foo"></h1>},

        '[img::sub:sub][*::sub:undef]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:sub][*::sub:0]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:sub][*::sub:1]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:sub][*::sub:string]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:sub][*::sub:regex]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},
        '[img::sub:sub][*::sub:sub]' =>
            qq{<img align="${ia_ial}" alt="${id_iat}" /><h1 align="${da_hal}"></h1>},

    );
}
