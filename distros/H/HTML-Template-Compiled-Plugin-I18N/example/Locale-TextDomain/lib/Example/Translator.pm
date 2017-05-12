package Example::Translator;

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);

# in mod_perl environment use Apache::Singleton::Request
use parent qw(Class::Singleton);

use Locale::TextDomain 1.17 qw(example ./LocaleData);
use HTML::Template::Compiled::Plugin::I18N;

sub new {
    my ($class, @more) = @_;

    return $class->instance(@more);
}

sub set_language {
    my ($class, $language) = @_;

    $ENV{LANGUAGE} = $language; ## no critic (LocalizedPunctuationVars)

    return $class;
}

sub get_language {
    my $class = shift;

    $ENV{LANGUAGE}
        or croak 'No language set';

    return $ENV{LANGUAGE};
}

sub translate {
    my ($class, $arg_ref) = @_;

    $class->get_language();
    my %gettext
        = exists $arg_ref->{gettext}
        ? %{ $arg_ref->{gettext} }
        : ();

    my $translation
        = exists $arg_ref->{context}
        ? (
            exists $arg_ref->{count}
            ? __npx(
                $arg_ref->{context},
                $arg_ref->{text},
                $arg_ref->{plural},
                $arg_ref->{count},
                %gettext,
            )
            : __px(
                $arg_ref->{context},
                $arg_ref->{text},
                %gettext,
            )
        )
        : (
            exists $arg_ref->{count}
            ? __nx(
                $arg_ref->{text},
                $arg_ref->{plural},
                $arg_ref->{count},
                %gettext,
            )
            : __x(
                $arg_ref->{text},
                %gettext,
            )
        );
    if ( exists $arg_ref->{escape} ) {
        $translation = HTML::Template::Compiled::Plugin::I18N->escape(
            $translation,
            $arg_ref->{escape},
        );
    }
    if ( exists $arg_ref->{formatter} ) {
        my $formatter_ref = $arg_ref->{formatter};
        for my $formatter ( @{$formatter_ref} ) {
            # Call here a formatter like Markdown
            if (lc $formatter eq lc 'Markdown') {
                # $translation = ... $tanslation;
            }
        }
    }
    if ( exists $arg_ref->{unescaped} ) {
        $translation = HTML::Template::Compiled::Plugin::I18N->expand_unescaped(
            $translation,
            $arg_ref->{unescaped},
        );
    }

    return $translation;
}

1;

__END__

$Id: Translator.pm 163 2009-12-03 09:20:38Z steffenw $