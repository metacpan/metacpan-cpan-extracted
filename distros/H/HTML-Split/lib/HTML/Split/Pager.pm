package HTML::Split::Pager;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_ro_accessors(qw( total_pages prev_page next_page ));

use HTML::Split;

sub new {
    my $class = shift;
    my %param = @_;

    return warn q{'html' is required}       unless $param{html};
    return warn q{'length' is required}     unless $param{length};
    return warn q{'length' is not numeric.} unless $param{length} =~ /^\d+$/;

    my @pages = HTML::Split->split(
        html        => $param{html},
        length      => $param{length},
        extend_tags => $param{extend_tags} || [],
    );

    my $self = bless {
        pages       => \@pages,
        total_pages => scalar @pages,
    }, $class;

    $self->current_page(1);

    return $self;
}

sub current_page {
    my ($self, $page) = @_;
    if (defined $page && $page > 0) {
        $self->{current_page} = $page;
        $self->{prev_page} = ($page - 1 > 0) ? $page - 1 : undef;
        $self->{next_page} = ($page + 1 <= $self->total_pages) ? $page + 1 : undef;
        return $self;
    }
    return $self->{current_page};
}

sub text {
    my $self = shift;
    return wantarray ? @{ $self->{pages} }
                     : $self->{pages}[$self->current_page - 1];
}

1;
__END__

=pod

=head1 NAME

HTML::Split::Pager - Pager that contains splitted HTMLs.

=head1 SYNOPSIS

  use HTML::Split::Pager;

  my $html = <<HTML;
  <div class="pkg">
  <h1>HTML::Split</h1>
  <p>Splitting HTML by number of characters.</p>
  </div>
  HTML;

  my $pager = HTML::Split::Pager->new(html => $html, lenght => 50);
  print $pager->text;

=head1 DESCRIPTION

=head1 CLASS METHODS

=head2 new

Create an instance of HTML::Split. Accept same arguments as I<split> method.

=head1 INSTANCE METHODS

=head2 current_page

Set/Get current page.

=head2 total_pages

Return the number of total pages.

=head2 next_page

Return the next page number. If the next page doesn't exists, return undef.

=head2 prev_page

Return the previous page number.  If the previous page doesn't exists, return undef.

=head2 text

Return the text of current page.

=head1 AUTHOR

Hiroshi Sakai E<lt>ziguzagu@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
