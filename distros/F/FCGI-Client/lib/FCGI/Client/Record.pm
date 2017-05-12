package FCGI::Client::Record;
use Any::Moose;
use FCGI::Client::Constant;
use FCGI::Client::RecordHeader;

has header     => ( is => 'ro', isa => 'FCGI::Client::RecordHeader', handles => [qw/request_id content_length type/] );
has content    => ( is => 'ro', isa => 'Str' );

__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

FCGI::Client::Record - record object for FCGI

=head1 SYNOPSIS

    my $record = FCGI::Client::Record->new(header => $header, content => $content);
    say $record->type;

=head1 DESCRIPTION

This module is record class for L<FCGI::Client>.

=head1 ATTRIBUTES

=over 4

=item header

'header' attribute is instance of L<FCGI::Client::RecordHeader>.

=item content

'content' attribute is string of record content.

=back

=head1 METHOD

=over 4

=item $self->request_id()

=item $self->content_length()

=item $self->type()

shortcut of $self->header->I<any_method>()

=back

=head1 SEE ALSO

L<FCGI::Client>

