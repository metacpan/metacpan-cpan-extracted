package HTML::FormHandler::Widget::Field::Role::SelectedOption;
# ABSTRACT: allow setting options from options keys
$HTML::FormHandler::Widget::Field::Role::SelectedOption::VERSION = '0.40068';
use Moose::Role;
use namespace::autoclean;

sub check_selected_option {
    my ( $self, $option, $fif ) = @_;
    my $selected_key = defined($option->{'selected'}) ?
        $option->{'selected'}
        : $option->{'checked'};
    if ( defined $selected_key ) {
        return $selected_key;
    } elsif ( defined $fif ) {
        return $fif eq $option->{'value'};
    } else {
        return;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Field::Role::SelectedOption - allow setting options from options keys

=head1 VERSION

version 0.40068

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
