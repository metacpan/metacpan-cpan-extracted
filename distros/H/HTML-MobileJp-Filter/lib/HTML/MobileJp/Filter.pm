package HTML::MobileJp::Filter;
use Any::Moose;
our $VERSION = '0.02';

has filters => (
    is      => 'rw',
    isa     => 'ArrayRef',
    required => 1,
    auto_deref => 1,
    default => sub { [] },
);

has stash => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

no Any::Moose;

use Class::Trigger;
use HTML::MobileJp::Filter::Content;

sub BUILD {
    my ($self) = @_;
    for my $config (@{ $self->filters }) {
        my $filter = do {
            my $module = $config->{module} =~ m{^\+(.*)$} ? $1 : __PACKAGE__ ."::$config->{module}";
            Any::Moose::load_class($module);
            $module->new($config);
        };
    
        $self->add_trigger(filter_process => sub {
            my $context = shift;
            $filter->mobile_agent($context->stash->{mobile_agent});
            
            my $ret = $filter->filter($context->stash->{content});
            if (defined $ret) {
                $context->stash->{content}->update($ret);
            }
        });
    }
}

sub filter {
    my ($self, %param) = @_;
    
    $self->stash({
        mobile_agent => $param{mobile_agent},
        content      => HTML::MobileJp::Filter::Content->new(html => $param{html}),
    });
    
    $self->call_trigger('filter_process');
    
    $self->stash->{content}->as_html;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

=head1 NAME

HTML::MobileJp::Filter - Glue of modules for fighting with Japanese mobile web

=head1 SYNOPSIS

  use HTML::MobileJp::Filter;
  use HTTP::MobileAgent;
  use YAML;

  my $filter = HTML::MobileJp::Filter->new(YAML::Load <<'...'
  ---
  filters:
    - module: DoCoMoCSS
      config:
        base_dir: /path/to/htdocs
    - module: DoCoMoGUID
    - module: FallbackImage
      config:
        template: '<img src="%s.gif" />'
        params:
          - unicode_hex
    - module: +MyApp::Filter::Foo
  ...
  );

  $html = $filter->filter(
      mobile_agent => HTTP::MobileAgent->new,
      html         => $html,
  );

=head1 DESCRIPTION

HTML::MobileJp::Filter is 偉大な先人たちがつくってくれた携帯サイトに役立つ
CPAN モジュールたちをつなげる薄いフレームワークです。

B<CAUTION: This module is still alpha, its possible the API will change!>

=head1 METHODS

=over 4

=item new( filters => [ ] )

=item filter( mobile_agent => $ua, html => $html )

=back

=head1 SEE ALSO

L<http://search.cpan.org/search?mode=module&query=HTML::MobileJp::Filter::>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 DEVELOPMENT

L<http://coderepos.org/share/browser/lang/perl/HTML-MobileJp-Filter>

#mobilejp on irc.freenode.net (I've joined as "tomi-ru")

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
