package t::lib::Builder;

use Test::DZil;

use constant MD_SAMPLE => <<"MD_SAMPLE";
# NAME

Foo::Bar - Foo and Bar

# VERSION

version 0.001

# SYNOPSIS

    use Foo::Bar;

# DESCRIPTION
Tellus proin aptent mattis vel pulvinar, et dui netus tellus.

Habitant ipsum nisl ad feugiat orci suscipit et sodales sodales.

Aliquam conubia sodales malesuada scelerisque, faucibus orci dapibus senectus eget.

MD_SAMPLE

# README.md's builder
sub tzil {
    shift;

    get_builder( 'README.md', @_ );
}

# any readme builder
sub tzil_for {
    shift;

    get_builder( @_ );
}

sub get_builder {
    my ( $filename, @params ) = @_;

    Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/' . $filename   => MD_SAMPLE,
                'source/dist.ini'       => simple_ini( 'GatherDir', @params ),
            }
        },
    );
}

1;
