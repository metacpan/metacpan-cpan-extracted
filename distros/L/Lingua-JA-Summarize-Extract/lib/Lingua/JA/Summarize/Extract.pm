package Lingua::JA::Summarize::Extract;

use strict;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw/ text rate /);

use Carp ();
use UNIVERSAL::require;

our $VERSION = '0.02';

use Lingua::JA::Summarize::Extract::ResultSet;

my %DefaultPlugins = (
    scoring  => 'Scoring::Base',
    parse    => 'Parser::Ngram',
    sentence => 'Sentence::Base',
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    for my $plugin (@{ $self->{plugins} }) {
        $self->add_plugin($plugin);
    }

    for my $method (keys %DefaultPlugins) {
        $self->add_plugin($DefaultPlugins{$method}) unless $self->can($method);
    }

    $self->{rate} ||= 1;

    $self;
}

sub add_plugin {
    my($self, $plugin) = @_;
    my $class = ref $self;

    my $package = ($plugin =~ /^\+(.+)$/) ? $1 :
        sprintf '%s::Plugin::%s', $class, $plugin;
    {
        no strict 'refs';
        $package->require or Carp::croak($@);
        unshift @{"$class\::ISA"}, $package;
    }
    $package->init($self);
}

sub extract {
    my($class, $text, @opt) = @_;
    my $self = ref $class ? $class : $class->new(@opt);

    utf8::decode($text);
    $self->text($text) if $text;

    Lingua::JA::Summarize::Extract::ResultSet->new({
        %{ $self },
        summary   => $self->summarize || [],
        sentences => $self->sentence || [],
    });
}

sub summarize {
    my($self, $text) = @_;
    $self->text($text) if $text;
    $self->scoring($self->parse);
}

1;

__END__

=head1 NAME

Lingua::JA::Summarize::Extract - summary generator for Japanese

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;
    use Lingua::JA::Summarize::Extract;

    my $text = '日本語の文章を適当に書く。';
    my $summary = Lingua::JA::Summarize::Extract->extract($text);

    print $summary->as_string;
    print "$summary";

    # cuts short to 20 length
    $summary->length(20);
    print "$summary";

    # mecab charset
    my $extractor = Lingua::JA::Summarize::Extract->new({ mecab_charset => 'utf8' });

=head1 DESCRIPTION

Lingua::JA::Summarize::Extract is a summary generator for Japanese text.
The extraction method can be changed with the plug-in mechanism. 

=head1 METHODS

=over 4

=item new([options])

a object is made by using the options.

=item extract(text[, options])

text is summarized.
blessed by using options if called direct.
return to Lingua::JA::Summarize::Extract::ResultSet object.

=back

=head1 OPTIONS

the content of processing can be changed by passing the constructor the options.

=over 4

=item plugins

the processing of split of word and line and the scoring etc. can be done by using another modules.
please pass it by the ARRAY reference.

=item rate

the weight at scoring can be changed.

=back

thing to refer to POD of each plugin when you want to examine other options.

=head1 THANKS TO

Tatsuhiko Miyagawa

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<http://gensen.dl.itc.u-tokyo.ac.jp/>, L<http://www.ryo.com/getsen/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
