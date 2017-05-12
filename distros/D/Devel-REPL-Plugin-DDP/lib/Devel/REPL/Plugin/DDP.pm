package Devel::REPL::Plugin::DDP;

use strict;
use 5.008_005;
our $VERSION = '0.05';

use Devel::REPL::Plugin;
use Data::Printer use_prototypes => 0;

around 'format_result' => sub {
    my $orig = shift;
    my $self = shift;
    my @to_dump = @_;
    my $out;
    for (@to_dump) {
        my $buf;
        p(\$_,
          output        => \$buf,
          colored       => 1,
          caller_info   => 0 );
        $out .= $buf;
    }
    chomp $out if defined $out;
    $self->$orig($out);
};

1;

__END__

=encoding utf-8

=head1 NAME

Devel::REPL::Plugin::DDP - Format return values with Data::Printer

=head1 DESCRIPTION

Use this in your Devel::REPL profile or load it from your C<re.pl> script.

You'll also want to make sure your profile or script runs the following:

    $_REPL->normal_color("reset");

or disables the L<standard Colors plugin|Devel::REPL::Plugin::Colors>.

=head1 AUTHOR

Thomas Sibley E<lt>tsibley@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Thomas Sibley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
