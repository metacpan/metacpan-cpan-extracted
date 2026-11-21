package FindBin::Testy;

use v5.40;

use Cwd                   qw( abs_path );
use File::Basename        qw( basename dirname    );
use File::Path            qw( make_path );
use File::Temp            qw( tempdir );
use File::Spec::Functions qw( catdir catfile catpath file_name_is_absolute rel2abs splitdir splitpath );
use List::Util            qw( first );
use Symbol                qw( qualify_to_ref );
use Test::More;
use YAML::Tiny;

sub run
{
    my $class = shift;

    my $t_dir     = rel2abs dirname dirname $0;
    my $group     = basename dirname $0;
    my $test_name = basename $0, '.t';

    # test the current module: the module is in the lib next to t.
    #
    # lib must exist; if it is a symlink it must resolve to the lib
    # next to the physical t directory, code outside the checkout is
    # not loaded.  add it to @INC unless it is already there, or a
    # blib is ("make test", "prove -b").

    my ( $vol, $dir )   = splitpath $t_dir, 1;
    my @dirz            = splitdir $dir;

    $dirz[-1]   = 'lib';

    my $lib_d   = catpath $vol, ( catdir @dirz ), '';

    -d $lib_d
    or die "Bogus test path: '$lib_d' from '$0' is not a directory.\n";

    if( -l $lib_d )
    {
        my ( $t_vol, $t_phys )  = splitpath abs_path( $t_dir ), 1;
        my @t_dirz              = splitdir $t_phys;

        $t_dirz[-1] = 'lib';

        my $expect  = catpath $t_vol, ( catdir @t_dirz ), '';
        my $found   = abs_path $lib_d;

        $found eq $expect
        or die "Bogus lib: symlink '$lib_d' resolves to '$found', "
        . "expected '$expect' next to the test directory.\n";
    }

    first
    {
        ! ref $_
        and
        (
            m{ (?: ^ | / ) blib / }x
            or rel2abs( $_ ) eq $lib_d
        )
    }
    @INC
    or unshift @INC, $lib_d;

    my $yaml_f  = catfile $t_dir, 'etc', 'tests.yaml';

    my $all
    = YAML::Tiny->read( $yaml_f )
    or die "Cannot read '$yaml_f': " . YAML::Tiny->errstr;

    my $config
    = $all->[0]{ $group }{ $test_name }
    or die "No config for '$group/$test_name' in '$yaml_f'";

    my @setup   = $config->{ setup  } ? @{ $config->{ setup  } } : ();
    my @args    = $config->{ args   } ? @{ $config->{ args   } } : ();
    my @expect  = @{ $config->{ expect } };
    my $var     = $config->{ var };

    # the setup paths are GROUP/BASE[/SUBDIR].  BASE is created as a
    # tempdir with a unique name in the group's directory, so leftovers
    # from earlier runs or tests running in parallel cannot collide
    # with it; CLEANUP removes it.  the unique name replaces BASE in
    # the setup and expect paths, base=BASE, and an exported variable
    # named after BASE.

    if( @setup )
    {
        my ( undef, $base ) = split m{/}, $setup[0];

        my $uniq_d  = tempdir "${base}_XXXXXX", DIR => catdir( $t_dir, $group ), CLEANUP => 1;
        my $uniq    = basename $uniq_d;

        s{ ^ ( \Q$group\E / ) \Q$base\E (?= / | $ ) }{$1$uniq}x
        for @setup, @expect;

        s{ ^ base= \Q$base\E $ }{base=$uniq}x
        for @args;

        defined $var && $var eq $base
        and $var = $uniq;

        make_path map { rel2abs catdir $t_dir, $_ } @setup;
    }

    require FindBin::libs;

    my $is_scalar = grep { $_ eq 'scalar' } @args;

    FindBin::libs->import( @args );

    my $check  = $config->{ check };

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
}

1
