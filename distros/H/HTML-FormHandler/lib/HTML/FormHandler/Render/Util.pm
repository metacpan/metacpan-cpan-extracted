package HTML::FormHandler::Render::Util;
# ABSTRACT: rendering utility
$HTML::FormHandler::Render::Util::VERSION = '0.40068';
use Sub::Exporter;
Sub::Exporter::setup_exporter({ exports => [ 'process_attrs', 'cc_widget', 'ucc_widget' ] } );


# this is a function for processing various attribute flavors
sub process_attrs {
    my ($attrs) = @_;

    my @use_attrs;
    my $javascript = delete $attrs->{javascript} || '';
    for my $attr( sort keys %$attrs ) {
        my $value = '';
        if( defined $attrs->{$attr} ) {
            if( ref $attrs->{$attr} eq 'ARRAY' ) {
                # we don't want class="" if no classes specified
                next unless scalar @{$attrs->{$attr}};
                $value = join (' ', @{$attrs->{$attr}} );
            }
            else {
                $value = $attrs->{$attr};
            }
        }
        push @use_attrs, sprintf( '%s="%s"', $attr, $value );
    }
    my $output = join( ' ', @use_attrs );
    $output = " $output" if length $output;
    $output .= " $javascript" if $javascript;
    return $output;
}

sub cc_widget {
    my $widget = shift;
    return '' unless $widget;
    if($widget eq lc $widget) {
        $widget =~ s/^(\w{1})/\u$1/g;
        $widget =~ s/_(\w{1})/\u$1/g;
    }
    return $widget;
}

sub ucc_widget {
    my $widget = shift;
    if($widget ne lc $widget) {
        $widget =~ s/::/_/g;
        $widget = ucfirst($widget);
        my @parts = $widget =~ /([A-Z][a-z]*)/g;
        $widget = join('_', @parts);
        $widget = lc($widget);
    }
    return $widget;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Render::Util - rendering utility

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

The 'process_attrs' takes a hashref and creates an attribute string
for constructing HTML.

    my $attrs => {
        some_attr => 1,
        placeholder => 'Enter email...",
        class => ['help', 'special'],
    };
    my $string = process_attrs($attrs);

...will produce:

    ' some_attr="1" placeholder="Enter email..." class="help special"'

If an arrayref is empty, it will be skipped. For a hash key of 'javascript'
only the value will be appended (without '$key=""');

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
