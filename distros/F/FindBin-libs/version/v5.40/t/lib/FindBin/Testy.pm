package FindBin::Testy;

use v5.40;

use File::Basename        qw( basename dirname    );
use File::Path            qw( make_path remove_tree );
use File::Spec::Functions qw( catdir catfile file_name_is_absolute rel2abs );
use Symbol                qw( qualify_to_ref );
use Test::More;
use YAML::Tiny;

sub run
{
    my $class = shift;

    my $t_dir     = rel2abs dirname dirname $0;
    my $group     = basename dirname $0;
    my $test_name = basename $0, '.t';

    require lib;
    lib->import( rel2abs catdir $t_dir, '..', 'lib' );

    my $yaml_f  = catfile $t_dir, 'etc', 'tests.yaml';

    my $all
    = YAML::Tiny->read( $yaml_f )
    or die "Cannot read '$yaml_f': " . YAML::Tiny->errstr;

    my $config
    = $all->[0]{ $group }{ $test_name }
    or die "No config for '$group/$test_name' in '$yaml_f'";

    my @setup      = $config->{ setup } ? @{ $config->{ setup } } : ();
    my @abs_setup  = map { rel2abs catdir $t_dir, $_ } @setup;
    my @to_cleanup = grep { ! -e $_ } @abs_setup;

    make_path @abs_setup if @abs_setup;

    require FindBin::libs;

    my @args      = $config->{ args } ? @{ $config->{ args } } : ();
    my $is_scalar = grep { $_ eq 'scalar' } @args;

    FindBin::libs->import( @args );

    my $check  = $config->{ check };
    my @expect = @{ $config->{ expect } };

    if( $check eq 'inc' )
    {
        for my $e ( @expect )
        {
            my @found
            = grep
            {
                file_name_is_absolute( $_ ) && m{/\Q$e\E$}
            }
            @INC;

            ok scalar @found, "\@INC contains absolute path ending in: $e";
        }
    }
    elsif( $check eq 'export' )
    {
        my $var = $config->{ var };
        my $ref = qualify_to_ref $var;

        my @found
        = $is_scalar
        ? ( ${ *{$ref}{ SCALAR } } // '' )
        : @{ *{$ref}{ ARRAY   } // [] };

        for my $e ( @expect )
        {
            my @matches
            = grep
            {
                file_name_is_absolute( $_ ) && m{/\Q$e\E$}
            }
            @found;

            ok scalar @matches, "\@$var contains absolute path ending in: $e";
        }
    }
    elsif( $check eq 'env' )
    {
        my $env_key = $config->{ env_key };
        my @found   = split /:/, $ENV{ $env_key } // '';

        for my $e ( @expect )
        {
            my @matches
            = grep
            {
                file_name_is_absolute( $_ ) && m{/\Q$e\E$}
            }
            @found;

            ok scalar @matches, "\$ENV{$env_key} contains absolute path ending in: $e";
        }
    }

    done_testing;

    remove_tree @to_cleanup if @to_cleanup;
}

1
