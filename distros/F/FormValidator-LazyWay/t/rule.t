use Test::Base;
use FormValidator::LazyWay::Rule;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use YAML::Syck;
use utf8;

no warnings 'once';
local $YAML::Syck::ImplicitUnicode = 1;
use warnings;

plan tests => 17 * blocks;

run {
    my $block  = shift;
    my $config = Load( $block->yaml );
    my $rule   = FormValidator::LazyWay::Rule->new( config => $config );

    is_deeply( $rule->defaults , $block->defaults , 'default' );
    is_deeply( $rule->modules, $block->modules ,'modules' );
    is_deeply( $rule->labels,  $block->labels , 'labels' );
    is( $rule->setting->{strict}{oppai}[0]{label}, $block->strict_oppai0 );
    is( $rule->setting->{strict}{oppai}[1]{label}, $block->strict_oppai1 );
    is( $rule->setting->{strict}{email}[0]{label}, $block->strict_email );
    is( $rule->setting->{strict}{email_mx}[0]{label}, $block->strict_email_mx );
    is( $rule->setting->{loose}{email}[0]{label}, $block->loose_email );
    is( $rule->setting->{loose}{email_mx}[0]{label}, $block->loose_email_mx );

    is( ref $rule->setting->{strict}{oppai}[0]{method},    'CODE' );
    is( ref $rule->setting->{strict}{oppai}[1]{method},    'CODE' );
    is( ref $rule->setting->{strict}{email}[0]{method},    'CODE' );
    is( ref $rule->setting->{strict}{email_mx}[0]{method}, 'CODE' );
    is( ref $rule->setting->{loose}{email}[0]{method},     'CODE' );
    is( ref $rule->setting->{loose}{email_mx}[0]{method},  'CODE' );

    is_deeply( $rule->setting->{strict}{email_mx}[0]{args}  , {'-mxcheck' => 1 } );
    is_deeply( $rule->setting->{loose}{email_mx}[0]{args}, {'-mxcheck' => 1 });
}

__END__

=== normal
--- defaults eval
{
    oppai => 'dekkai' , 
}
--- labels eval
{
    'Email#email' => {
        'method' => 'email',
        'package' => 'FormValidator::LazyWay::Rule::Email',
        'alias'   => undef,
    },
    'Email#email_loose' => {
        'method' => 'email_loose',
        'package' => 'FormValidator::LazyWay::Rule::Email',
        'alias'   => undef,
    },
    '+MyRule::Oppai#name' => {
        'method' => 'name',
        'package' => 'MyRule::Oppai',
        'alias'   => undef,

    }
}
--- modules eval
[qw/
  FormValidator::LazyWay::Rule::Email
  MyRule::Oppai
/]
--- yaml
rules :
    - Email
    - +MyRule::Oppai
defaults :
    oppai : dekkai
setting :
  strict :
    oppai :
        rule :
            - Email#email 
            - +MyRule::Oppai#name
    email :
        rule :
            - Email#email 
    email_mx :
        rule :
            - Email#email :
                -mxcheck: 1
  loose :
    email :
        rule :
            - Email#email_loose 
    email_mx :
        rule :
            - Email#email_loose :
                -mxcheck: 1
--- strict_email chomp
Email#email
--- strict_oppai0 chomp
Email#email
--- strict_oppai1 chomp
+MyRule::Oppai#name
--- strict_email_mx chomp
Email#email
--- loose_email chomp
Email#email_loose
--- loose_email_mx chomp
Email#email_loose
=== alialias
--- defaults eval
{
    oppai => 'dekkai' , 
}
--- labels eval
{
    'Email#email' => {
        'method' => 'email',
        'package' => 'FormValidator::LazyWay::Rule::Email',
        'alias'   => 'email#email',
    },
    'Email#email_loose' => {
        'method' => 'email_loose',
        'package' => 'FormValidator::LazyWay::Rule::Email',
        'alias'   => 'email#email_loose',
    },
    '+MyRule::Oppai#name' => {
        'method' => 'name',
        'package' => 'MyRule::Oppai',
        'alias'   => 'oppai#name',
    }
}
--- modules eval
[qw/
  FormValidator::LazyWay::Rule::Email
  MyRule::Oppai
/]
--- yaml
rules :
    - email=Email
    - oppai=+MyRule::Oppai
defaults : 
    oppai : dekkai
setting :
  strict :
    oppai :
        rule :
            - email#email
            - oppai#name
    email :
        rule :
            - email#email
    email_mx :
        rule :
            - email#email :
                -mxcheck: 1
  loose :
    email :
        rule :
            - email#email_loose 
    email_mx :
        rule :
            - email#email_loose :
                -mxcheck: 1
--- strict_email chomp
Email#email
--- strict_oppai0 chomp
Email#email
--- strict_oppai1 chomp
+MyRule::Oppai#name
--- strict_email_mx chomp
Email#email
--- loose_email chomp
Email#email_loose
--- loose_email_mx chomp
Email#email_loose
