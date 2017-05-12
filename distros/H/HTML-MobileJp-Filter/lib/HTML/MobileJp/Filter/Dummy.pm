package HTML::MobileJp::Filter::Dummy;
use Any::Moose;

with 'HTML::MobileJp::Filter::Role';

has '+config' => (
    default => sub {{
        prefix => 'dummy:{',
        suffix => '}',
    }},
);

sub filter {
    my ($self, $content) = @_;
    
    return join('',
        $self->config->{prefix},
        $content->stringfy,
        $self->config->{suffix},
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

HTML::MobileJp::Filter::Dummy - Dummy filter

=head1 SYNOPSIS

  - module: Dummy

=head1 DESCRIPTION

HTML の最初と最後に config の C<prefix> の値と C<suffix> の値を付けて
返すだけのダミーモジュールです。

=head1 CONFIG AND DEFAULT VALUES

  prefix => 'dummy:{',
  suffix => '}',

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=cut
