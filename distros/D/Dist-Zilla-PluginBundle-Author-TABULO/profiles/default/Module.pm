package {{$name}};

use strict;
use warnings;

our $VERSION = '0.001';

1;

=head1 NAME

{{$name}} - Module abstract placeholder text

=head1 SYNOPSIS

=for comment Brief examples of using the module.

=head1 DESCRIPTION

=for comment The module's description.

=head1 AUTHOR

{{ join "\n\n", @{$dist->authors} }}

=head1 COPYRIGHT AND LICENSE

{{$dist->license->notice}}
