package HTML::MobileJp::Filter::DoCoMoGUID;
use Any::Moose;

with 'HTML::MobileJp::Filter::Role';

use HTML::StickyQuery::DoCoMoGUID;

sub filter {
    my ($self, $content) = @_;
    
    unless ($self->mobile_agent->is_docomo) {
        return;
    }
    
    HTML::StickyQuery::DoCoMoGUID->new->sticky( scalarref => \$content->stringfy );
}

1;
__END__

=encoding utf-8

=head1 NAME

HTML::MobileJp::Filter::DoCoMoGUID - DoCoMo の場合 guid=ON を付ける

=head1 SYNOPSIS

  - module: DoCoMoGUID

=head1 CONFIG AND DEFAULT VALUES

=head1 SEE ALSO

L<HTML::StickyQuery::DoCoMoGUID>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=cut
