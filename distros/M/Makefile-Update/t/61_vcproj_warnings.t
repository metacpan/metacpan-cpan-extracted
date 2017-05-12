use strict;
use warnings;
use autodie;
use Test::More;
use Test::Warn;

BEGIN { use_ok('Makefile::Update::VCProj'); }

sub do_update
{
    my ($instr, $sources) = @_;

    my $fullinput = <<EOF;
<?xml version="1.0" encoding="Windows-1252"?>
<VisualStudioProject
	ProjectType="Visual C++"
	Version="7.10"
	Name="base"
	ProjectGUID="{79F1691B-08C4-55BB-985E-FDDB0BC8753C}">
	<Platforms>
		<Platform
			Name="Win32"/>
	</Platforms>
	<Files>
$instr
	</Files>
</VisualStudioProject>
EOF

    open my $out, '>', \my $outstr;
    open my $in, '<', \$fullinput;

    update_vcproj($in, $out, $sources)
}

warning_like {
        do_update('', [qw(foo.pl)], [])
    }
    qr/^No filter defined.*/,
    'unknown file type warning given';

warning_like {
        do_update(<<'EOF',
		<Filter
			NoName="Source Files"
			UniqueIdentifier="{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}">
		</Filter>
EOF
            [qw(foo.cpp)]
        )
    }
    qr/^Unrecognized format for <Filter> tag.*/,
    'unrecognized filter warning given';

warning_like {
        do_update(<<'EOF',
		<Filter
			Name="Source Files"
			UniqueIdentifier="{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}">
            <Filter
                Name="Some Special Files"
                UniqueIdentifier="{yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy}">
            </Filter>
		</Filter>
EOF
            [qw(foo.cpp)]
        )
    }
    qr/^Nested <Filter> tag.*is not supported.*/,
    'nested filter warning given';

warning_like {
        do_update(<<'EOF',
		<Filter
			Name="Source Files"
			UniqueIdentifier="{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}">
			<File
                AbsolutePath="foo.cpp">
            </File>
		</Filter>
EOF
            [qw(foo.cpp)]
        )
    }
    qr/^Unrecognized format for <File> tag.*/,
    'unrecognized file warning given';

warning_like {
        do_update(<<'EOF',
		<Filter
			Name="Source Files"
			UniqueIdentifier="{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}">
			<File
				RelativePath="foo.cpp">
			</File>
			<File
				RelativePath="foo.cpp">
			</File>
		</Filter>
EOF
            [qw(foo.cpp)]
        )
    }
    qr/^Duplicate file.*/,
    'duplicate file warning given';

done_testing()
