package Hatena::Formatter;
use base qw(Class::Accessor::Fast);
use strict;
use utf8;
use warnings;
use Hatena::Formatter::AutoLinkHatenaID;
use Hatena::Keyword 0.04;
use Text::Hatena;

our $VERSION = '0.03';

__PACKAGE__->mk_accessors(qw( text html ));

$Text::Hatena::AutoLink::SCHEMES->{id} = 'Hatena::Formatter::AutoLinkHatenaID';

sub new {
    my $class = shift;
    my %opt   = @_;

    my $self = bless {
        %opt,
        hooks => {},
    }, $class;
    $self->init;

    $self;
}

sub init {
    my $self = shift;

    if (ref($self->{text_config})) {
        # hatena text init
        my $hatenaid_href = delete $self->{text_config}->{hatenaid_href};
        $Hatena::Formatter::AutoLinkHatenaID::HREF = $hatenaid_href if $hatenaid_href;
        $self->{htext} = Text::Hatena->new(
            sectionanchor => "\x{25a0}",
            %{ $self->{text_config} },
        );
    }
    if (ref($self->{keyword_config})) {
        # hatena keyword init
        $self->{hkeyword} = Hatena::Keyword->new();
    }
}

sub register {
    my $self = shift;
    my %opt  = @_;
    return unless $opt{hook} && ref($opt{callback});
    push @{ $self->{hooks}->{$opt{hook}} }, \%opt;
}

sub run_hook {
    my($self, $hook) = @_;
    for my $action (@{ $self->{hooks}->{$hook} }) {
        $action->{callback}($self, $action->{option});
    }
}

sub process {
    my($self, $text) = @_;
    $self->text($text) if $text;
    $text = $self->text;
    return unless $text;

    $self->html($text);
    $self->run_hook('suprepre_init');
    $text = $self->html;
    my $i = 0;
    my %tmp = ();
    $text =~ s{(^>\|\|.*?^\|\|<)}{
        $i++;
        $tmp{$i} = $1;
        "<%!Hatena super pre--$i--%>";
    }gsme;
    $self->html($text);

    if ($self->{htext}) {
        $self->run_hook('text_init');
        $self->{htext}->parse($self->html);
        $self->html($self->{htext}->html);

        #super pre formatting
        for my $c (keys %tmp) {
            $self->{htext}->parse($tmp{$c});
            $tmp{$c} = $self->{htext}->html;
            $tmp{$c} =~ s{^<div class="section">\n\t(.+)\n</div>$}{$1}sm;
        }
    }
    $self->run_hook('text_finalize');

    if (ref($self->{hkeyword})) {
        $self->run_hook('keyword_init');
        $self->html($self->{hkeyword}->markup_as_html($self->html, {
            a_class => 'keyword',
            %{ $self->{keyword_config} },
        }));
    }
    $self->run_hook('keyword_finalize');

    $text = $self->html;
    $text =~ s{<p><%!Hatena super pre--(\d+)--%></p>}{$tmp{$1}}gsme;
    $self->html($text);
    $self->run_hook('suprepre_finalize');

    $self->html;
}

1;

__END__

=head1 NAME

Hatena::Formatter - converts text into html with almost Hatena style.

=head1 SYNOPSIS

  use Hatena::Formatter;

  my $formatter = Hatena::Formatter->new(
      text_config => {}, # set the Text::Hatena options.
      keyword_config => {}, # set the Hatena::Keyword options.
  );
  $formatter->process($text);
  print $formatter->html;

=head1 DESCRIPTION

L<Text::Hatena> used generates html string with Hatena Style.
and L<Hatena::Keyword> used allows you to mark up a text as HTML with the Hatena keywords.
When you want to adjust the option of L<Text::Hatena> and L<Hatena::Keyword>, it can be done. 

In the process of each processing, it is also possible to do original processing hooking to process converted HTML. 

=head1 METHODS

=over 4

=item new

  $formatter = Hatena::Formatter->new(
      text_config => { hatenaid_href => '?id=%s' },
      keyword_config => {},
  );

creates an instance of Hatena::Formatter.

C<text_config> is option that L<Text::Hatena> uses.
When this option is omitted, the processing of L<Text::Hatena> is not executed. 

C<hatenaid_href> is Enhancing for Hatena::Formatter.
The format of link href used by the id notation of Hatena is specified. id is substituted 
for %s. (It is possible to omit it. )

C<keyword_config> is option that L<Hatena::Keyword> uses.
When this option is omitted, the processing of L<Hatena::Keyword> is not executed. 

=item register

  $formatter2->register( hook => 'text_finalize', callback => sub { my($context, $option) = @_; } , option => {});

callback to do the hook in process is registered. 

=item process

  $formatter->process($text);

conversion processing.

=item html

  $html = $formatter->html;

returns html string generated.

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 THANKS TO

TransFreeBSD, Naoya Ito, otsune, tokuhirom

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Text::Hatena>, L<Hatena::Keyword>

=cut

