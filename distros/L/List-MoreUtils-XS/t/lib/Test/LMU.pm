package Test::LMU;

use strict;

require Exporter;
use Test::More import => ['!pass'];
use Carp qw/croak/;

use base qw(Test::Builder::Module Exporter);

our @EXPORT    = qw(freeze is_true is_false is_defined is_undef is_dying not_dying grow_stack leak_free_ok);
our @EXPORT_OK = qw(freeze is_true is_false is_defined is_undef is_dying not_dying grow_stack leak_free_ok);

my $CLASS = __PACKAGE__;

eval "use Storable qw();";
$@ or Storable->import(qw(freeze));
__PACKAGE__->can("freeze") or eval <<'EOFR';
use inc::latest 'JSON::PP';
use JSON::PP qw();
sub freeze {
    my $json = JSON::PP->new();
    $json->encode($_[0]);
}
EOFR

######################################################################
# Support Functions

sub is_true
{
    @_ == 1 or croak "Expected 1 param";
    my $tb = $CLASS->builder();
    $tb->ok($_[0], "is_true ()");
}

sub is_false
{
    @_ == 1 or croak "Expected 1 param";
    my $tb = $CLASS->builder();
    $tb->ok(!$_[0], "is_false()");
}

sub is_defined
{
    @_ < 1 or croak "Expected 0..1 param";
    my $tb = $CLASS->builder();
    $tb->ok(defined($_[0]), "is_defined ()");
}

sub is_undef
{
    @_ <= 1 or croak "Expected 0..1 param";
    my $tb = $CLASS->builder();
    $tb->ok(!defined($_[0]), "is_undef()");
}

sub is_dying
{
    @_ == 1 or @_ == 2 or croak "is_dying(name => code)";
    my ($name, $code);
    $name = shift if @_ == 2;
    $code = shift;
    ref $code eq "CODE" or croak "is_dying(name => code)";
    my $tb = $CLASS->builder();
    eval { $code->(); };
    my $except = $@;
    chomp $except;
    $tb->ok($except, "$name is_dying()") and note($except);
}

sub not_dying
{
    @_ == 1 or @_ == 2 or croak "not_dying(name => code)";
    my ($name, $code);
    $name = shift if @_ == 2;
    $code = shift;
    ref $code eq "CODE" or croak "not_dying(name => code)";
    my $tb = $CLASS->builder();
    eval { $code->(); };
    my $except = $@;
    chomp $except;
    $tb->ok(!$except, "$name not_dying()") or diag($except);
}

my @bigary = (1) x 500;

sub func { }

sub grow_stack
{
    func(@bigary);
}

my $have_test_leak_trace = eval { require Test::LeakTrace; 1 };

sub leak_free_ok
{
    while (@_)
    {
        my $name = shift;
        my $code = shift;
      SKIP:
        {
            skip 'Test::LeakTrace not installed', 1 unless $have_test_leak_trace;
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            &Test::LeakTrace::no_leaks_ok($code, "No memory leaks in $name");
        }
    }
}

{

    package DieOnStringify;
    use overload '""' => \&stringify;
    sub new { bless {}, shift }
    sub stringify { die 'DieOnStringify exception' }
}

1;

=head1 AUTHOR

Jens Rehsack E<lt>rehsack AT cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 - 2017 by Jens Rehsack

All code added with 0.417 or later is licensed under the Apache License,
Version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

All code until 0.416 is licensed under the same terms as Perl itself,
either Perl version 5.8.4 or, at your option, any later version of
Perl 5 you may have available.

=cut
