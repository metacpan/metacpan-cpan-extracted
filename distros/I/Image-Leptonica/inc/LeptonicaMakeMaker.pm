package inc::LeptonicaMakeMaker;
use Moose;

extends qw( Dist::Zilla::Plugin::MakeMaker::Awesome );


override _build_WriteMakefile_args => sub { +{
    %{ super() },
} };

override _build_WriteMakefile_dump => sub {
	my $str = super();
	$str .= <<'END';
use Inline::MakeMaker;
use ExtUtils::Depends;
use File::Spec::Functions;
use File::Path qw(make_path);
use File::Copy;
$WriteMakefileArgs{CONFIGURE} = sub {
	require Alien::Leptonica;
	my $l = Alien::Leptonica->new;
	my $pkg = ExtUtils::Depends->new('Image::Leptonica',);
	$pkg->set_inc( $l->cflags );
	$pkg->set_libs( $l->libs );

	# make path to install to
	my @dir = qw( lib Image Leptonica Install );
	make_path catfile @dir;

	my $typemap_path = catfile( @dir, 'typemap');
	$pkg->add_typemaps( $typemap_path );
	# copy typemap into that path
	copy( 'typemap', $typemap_path );

	# save config to that path
	$pkg->save_config( catfile( @dir, 'Files.pm' ) );

	+{ CCFLAGS => $l->cflags,
	   LIBS => $l->libs,
	   $pkg->get_makefile_vars()  };
};
END
	$str;
};

__PACKAGE__->meta->make_immutable;
