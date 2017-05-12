package HTML::MobileJp::Filter::EntityReference;
use Any::Moose;

with 'HTML::MobileJp::Filter::Role';

has '+config' => (
    default => sub {{
        force => 0,
    }},
);

use Encode::JP::Mobile ':props';
use HTML::Entities::ConvertPictogramMobileJp;

sub filter {
    my ($self, $content) = @_;
    
    if ($self->mobile_agent->is_non_mobile) {
        if ($self->config->{force}) {
            $content =~ s{(&\#x([A-Z0-9]+);)}{
                my $code = $1;
                my $char = chr hex $2;
                $char =~ /\p{InMobileJPPictograms}/ ? $char : $code;
            }ge;
        }
    } else {
        $content = convert_pictogram_entities(
            mobile_agent => $self->mobile_agent,
            html         => $content->stringfy,
        );
    }
    
    $content;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

=head1 NAME

HTML::MobileJp::Filter::EntityReference - i絵文字のコピペの代わりに実体参照で書いておける

=head1 SYNOPSIS

  - module: EntityReference

=head1 CONFIG AND DEFAULT VALUES

  force => 0,

default ではこのフィルタは単純な HTML::Entities::ConvertPictogramMobileJp の
単純なラッパーで、PC の場合は何もしません。C<force> に 1 を指定すると
PC の場合も Unicode 16進数文字参照を Unicode へと置換するようになります。

=head1 SEE ALSO

L<HTML::Entities::ConvertPictogramMobileJp>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=cut
