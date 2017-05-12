package inc::MyMakeMaker;

use strict;
use warnings;

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub {
    my $self = shift;

    my $args = super();

    delete $args->{VERSION};
    $args->{VERSION_FROM} = 'lib/Math/Int64.pm';

    return $args;
};

override _build_WriteMakefile_dump => sub {
    my $self = shift;

    my $dump = super();
    $dump .= <<'EOF';
$WriteMakefileArgs{DEFINE} = join ' ',
                               grep defined, _backend_define(),
                                             _int64_define(),
                                             _has_stdint_h_define();
EOF

    return $dump;
};

override _build_MakeFile_PL_template => sub {
    my $self     = shift;
    my $template = super();

    $template =~ s/^(WriteMakefile)/_check_for_capi_maker();\n\n$1/m;

    my $extra = do { local $/; <DATA> };
    return $template . $extra;
};

__PACKAGE__->meta()->make_immutable();

1;

__DATA__

use lib 'inc';
use Config::AutoConf;

sub _check_for_capi_maker {
    return unless -d '.git';

    unless ( eval { require Module::CAPIMaker; 1; } ) {
        warn <<'EOF';

  It looks like you're trying to build Math::Int64 from the git repo. You'll
  need to install Module::CAPIMaker from CPAN in order to do this.

EOF

        exit 1;
    }
}

my $autoconf;
sub autoconf {
    unless (defined $autoconf) {
        $autoconf = Config::AutoConf->new;
        unless ($autoconf->check_default_headers()) {
            warn 'Config::AutoConf check for default headers failed!';
            exit 1;
        }
    }
    $autoconf;
}

sub _int64_define {
    return '-DUSE_INT64_T' if autoconf->check_type('int64_t');
    return '-DUSE___INT64' if autoconf->check_type('__int64');
    return '-DUSE_INT64_DI'
        if autoconf->check_type('int __attribute__ ((__mode__ (DI)))');

    warn <<'EOF';

  It looks like your compiler doesn't support a 64-bit integer type (one of
  "int64_t" or "__int64"). One of these types is necessary to compile the
  Math::Int64 module.

EOF

    exit 1;
}

sub _has_stdint_h_define {
    return '-DHAS_STDINT_H' if autoconf->check_header('stdint.h');
    undef
}

sub _backend_define {
    my $backend
        = defined $ENV{MATH_INT64_BACKEND} ? $ENV{MATH_INT64_BACKEND}
        : $Config::Config{ivsize} >= 8     ? 'IV'
        : $Config::Config{doublesize} >= 8 ? 'NV'
        :                                    die <<'EOF';
Unable to find a suitable representation for int64 on your system.
Your Perl must have ivsize >= 8 or doublesize >= 8.
EOF

    print "Using $backend backend\n";

    return '-DINT64_BACKEND_' . $backend;
}

package MY;

sub postamble {
    my $self = shift;

    my $author = $self->{AUTHOR};
    $author = join( ', ', @$author ) if ref $author;

    if ($^O =~ /MSWin/) {
        $author = qq{"$author"};
    }
    else {
        $author =~ s/'/'\''/g;
        $author = qq{'$author'};
    }

    return <<"MAKE_FRAG";
c_api.h: c_api.decl
	perl -MModule::CAPIMaker -emake_c_api module_name=\$(NAME) module_version=\$(VERSION) author=$author
MAKE_FRAG
}

sub init_dirscan {
    my $self = shift;
    $self->SUPER::init_dirscan(@_);
    push @{ $self->{H} }, 'c_api.h'
        unless grep { $_ eq 'c_api.h' } @{ $self->{H} };
    return;
}
