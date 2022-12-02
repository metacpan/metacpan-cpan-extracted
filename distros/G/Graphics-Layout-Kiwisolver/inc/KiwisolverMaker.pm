package inc::KiwisolverMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;
	my $template = super();

	# Use XS::Install
	$template =~ s/\Quse ExtUtils::MakeMaker\E/use XS::Install;\n$&/sg;
	$template =~ s/\QWriteMakefile(\E/write_makefile(/sg;

	return $template;
};

override _build_WriteMakefile_args => sub { +{
		# Add LIBS => to WriteMakefile() args
		%{ super() },
		BIN_DEPS  => ['XS::Framework'],
		PARSE_XS  => 'XS::Framework::ParseXS',
		CPLUS   => 14,
} };

override _build_WriteMakefile_dump => sub {
	my $str = super();
	$str .= <<'END';
$WriteMakefileArgs{CONFIGURE} = sub {
	require Alien::Kiwisolver;
	require Config;
	my $k = Alien::Kiwisolver->new;
	+{
		CCFLAGS => join(" ",
			$Config::Config{ccflags},
			$k->cflags, '-std=c++14',
		),
		LIBS => $k->libs
	};
};
END
	$str;
};

__PACKAGE__->meta->make_immutable;
