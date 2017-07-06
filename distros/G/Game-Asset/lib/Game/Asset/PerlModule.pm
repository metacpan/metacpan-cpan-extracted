# Copyright (c) 2016  Timm Murray
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
package Game::Asset::PerlModule;
$Game::Asset::PerlModule::VERSION = '0.6';
use strict;
use warnings;
use Moose;
use namespace::autoclean;


use constant type => 'pm';

with 'Game::Asset::Type';

has 'package' => (
    is => 'ro',
    isa => 'Str',
    writer => '_set_package',
);


sub _process_content
{
    my ($self, $pm_text) = @_;

    my $pack = eval $pm_text;
    die $@ if $@;

    $self->_set_package( $pack );
    return;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  Game::Asset::PerlModule - A game asset that's a Perl module

=head1 DESCRIPTION

Handles an asset that's a Perl module.

The code in the module is loaded up much like any other Perl module. As with 
any other Perl module, you should trust the source of the code being loaded.

=head1 WRITING THE MODULE

For the most part, you would write the module code the same as any other module.
There is only one small change: instead of having C<1;> as your last line to 
return a true value, you should have C<__PACKAGE__;>.  
C<Game::Asset::PerlModule> uses this to get the package name of the module.

While it is possible to load multiple packages into a single file, it's 
recommended to avoid this within C<Game::Asset::PerlModule>.

=head1 METHODS

=head2 package

Returns the name of the package that was loaded.

=cut
