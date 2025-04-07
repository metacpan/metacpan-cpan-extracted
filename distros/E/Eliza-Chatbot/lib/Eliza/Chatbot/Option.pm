package Eliza::Chatbot::Option;

use Moo;
use MooX::LazierAttributes;
use Eliza::Chatbot::ScriptParser;

attributes (
    [qw/script_file debug_text transform_text botprompt userprompt/] => [ rw, '', {lzy}],
    [qw/prompts_on memory_on likelihood_of_using_memory/] => [ rw, 1, {lzy}],
    name => [ rw, 'Eliza', {lzy}],
    debug => [rw, 0, {lzy}],
    max_memory_size => [rw, 5, {lzy}],
    memory => [rw, [ ], {lzy}],
    data => [ro, nan, {lzy, bld}]
);

sub _build_data {
    my $self = shift;
    my $parser = Eliza::Chatbot::ScriptParser->new(script_file => $self->script_file);
    $parser->parse_script_data;
    return $parser;
}

sub myrand {
    my ($self, $max) = @_;
    my $n = defined $max ? $max : 1;
    return rand($n);
}

sub welcome_message {
    my $self = shift;
    my $initial = $self->data->initial;
    return $initial->[ $self->myrand( scalar @{$initial} ) ];
}

1;

__END__

=head1 NAME

Eliza::Chatbot::Options 

=head1 VERSION

Version 0.11

=head1 Options

=over

=item name 

=item script_file

=item debug

=item debug_text

=item transform_text

=item prompts_on

=item memory_on

=item botprompt

=item userprompt

=item max_memory_size

=item likelihood_of_using_memory

=item memory

=item data

=back

=head1 SUBROUTINES/METHODS

=head2 myrand

    $bot->options->myrand(10)

Generates a random number between 0 and the integer passed in.

=head2 welcome_message

    $bot->options->welcome_message

Returns a greeting message.

=head1 AUTHOR

LNATION email@lnation.org

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

