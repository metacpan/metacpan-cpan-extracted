# Copyright (c) 2017  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Graphics::GVG::Args;
$Graphics::GVG::Args::VERSION = '0.91';
use strict;
use warnings;
use Moose;
use namespace::autoclean;

use constant INTEGER => 0;
use constant COLOR => 1;
use constant NUMBER => 2;

has 'named_args' => (
    is => 'ro',
    isa => 'HashRef[Str]',
    default => sub {{}},
);
has 'positional_args' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub {[]},
);

sub names
{
    my ($self, @names) = @_;
    return if ! @{ $self->positional_args };
    my @positional_args = @{ $self->positional_args };
    my $num_args = scalar( @positional_args );
    my $num_names = scalar @names;
    die "Got $num_names names, but expected $num_args\n"
        if $num_names != $num_args;

    foreach my $i (0 .. $#names) {
        my $name = $names[$i];
        my $value = $positional_args[$i];
        $self->named_args->{$name} = $value;
    }

    return;
}

sub arg
{
    my ($self, $name, $expect_type) = @_;

    my $value = $self->named_args->{$name};
    if( $self->COLOR == $expect_type ) {
        $value =~ s/\A#//;
        $value = hex $value;
    }

    return $value;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

