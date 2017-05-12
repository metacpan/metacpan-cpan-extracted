package File::Chunk::Script;
{
  $File::Chunk::Script::VERSION = '0.0035';
}
BEGIN {
  $File::Chunk::Script::AUTHORITY = 'cpan:DHARDISON';
}
use Moose::Role;
use namespace::autoclean;

with 'MooseX::Getopt::GLD' => { getopt_conf => [ 'gnu_getopt' ] };

around _get_cmd_flags_for_attr => sub {
    my $next = shift;
    my ( $class, $attr, @rest ) = @_;

    my ( $flag, @aliases ) = $class->$next($attr, @rest);
    $flag =~ tr/_/-/
        unless $attr->does('MooseX::Getopt::Meta::Attribute::Trait')
            && $attr->has_cmd_flag;

    return ( $flag, @aliases );
};

requires 'run';


1;

__END__

=pod

=head1 NAME

File::Chunk::Script

=head1 VERSION

version 0.0035

=head1 AUTHOR

Dylan William Hardison <dylan@hardison.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
