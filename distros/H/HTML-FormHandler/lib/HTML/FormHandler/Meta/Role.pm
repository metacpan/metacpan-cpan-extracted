package    # hide from Pause
    HTML::FormHandler::Meta::Role;
# ABSTRACT: field_list and apply_list

use Moose::Role;


has 'field_list' => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
    handles  => {
        add_to_field_list => 'push',
        clear_field_list => 'clear',
        has_field_list => 'count',
    }
);

has 'apply_list' => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
    handles  => {
        add_to_apply_list => 'push',
        has_apply_list => 'count',
        clear_apply_list => 'clear',
    }
);

has 'page_list' => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
    handles  => {
        add_to_page_list => 'push',
        has_page_list => 'count',
        clear_page_list => 'clear',
    }
);

has 'block_list' => (
    traits    => ['Array'],
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
    handles  => {
        add_to_block_list => 'push',
        has_block_list => 'count',
        clear_block_list => 'clear',
    }
);

has 'found_hfh' => ( is => 'rw', default => '0' );

use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Meta::Role - field_list and apply_list

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Add metaclass to field_list attribute

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
