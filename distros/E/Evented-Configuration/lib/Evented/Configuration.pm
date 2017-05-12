# Copyright (c) 2016, Mitchell Cooper
#
# Evented::Configuration:
#
# a configuration file parser and event-driven configuration class.
# Evented::Configuration is based on UICd::Configuration, the class of the UIC daemon.
# UICd's parser was based on juno5's parser, which evolved from juno4, juno3, and juno2.
# Early versions of Evented::Configuration were also found in several IRC bots, including
# foxy-java. Evented::Configuration provides several convenience fetching methods.
#
# Events:
#
# each time a configuration value changes, change:blocktype/blockname:key is fired. For unnamed
# blocks, the block type is omitted. For example, a block named 'chocolate' of type
# 'cookies' would fire the event 'change:cookies/chocolate:favorite' when its 'favorite' key
# is changed. An unnamed block of type 'fudge' would fire the event 'change:fudge:peanutbutter'
# when its 'peanutbutter' key is changed.
#
# If a value never existed, new values fire change events as well. If you want your
# listeners to respond to certain values even when the configuration is first loaded,
# simply add the listeners before calling parse_config(). If you wish for the opposite
# behavior, do the opposite: apply the handlers after calling parse_config().
#
# All events are fired with:
#    $old - first argument, the former value of this configuration key.
#    $new - second argument, the new value of this configuration key.
#
# The easiest way to attach configuration change events is with the on_change() method.
# It is also the safest way because event names could possibly change in the future.
# For example:
#
# $conf->on_change(['someBlockType', 'someBlockName'], 'key', sub {
#     my ($event, $old, $new) = @_;
#     ...
# });
#
# You can also add additional hash arguments for ->register_event() to the end.
#

package Evented::Configuration;

use warnings;
use strict;
use utf8;
use parent 'Evented::Object';

our $VERSION = '3.93';      # now incrementing by 0.01

sub on  () { 1 }
sub off () { undef }

# create a new configuration instance.
sub new {
    my ($class, %opts) = (shift, @_);

    # if we still have no defined conffile, we must give up now.
    if (!defined $opts{conffile}) {
        $@ = 'no configuration file (conffile) option specified.';
        return;
    }

    # if 'hashref' is provided, use it.
    $opts{conf} = $opts{hashref} || $opts{conf} || {};

    # return the new configuration object.
    return bless \%opts, $class;

}

# parse the configuration file.
sub parse_config {
    my ($conf, $i, $block, $name, $config) = shift;
    open $config, '<', $conf->{conffile} or return;

    while (my $line = <$config>) {
        $i++;
        $line = trim($line);
        next unless length $line;
        next if $line =~ m/^#/;
        my ($key, $val, $val_changed_maybe);

        # a block with a name.
        if ($line =~ m/^\[(.*?):(.*)\]$/) {
            $block = trim($1);
            $name  = trim($2);
        }

        # a nameless block.
        elsif ($line =~ m/^\[(.*)\]$/) {
            $block = 'section';
            $name  = trim($1);
        }

        # a boolean key.
        elsif ($line =~ m/^\s*([\w:]+)\s*(#.*)*$/ && defined $block) {
            $key = trim($1);
            $val++;
            $val_changed_maybe++;
        }

        # a key and value.
        elsif ($line =~ m/^\s*([\w:]+)\s*[:=]+(.+)$/ && defined $block) {
            $key = trim($1);
            $val = eval trim($2);
            $val_changed_maybe++;
            if ($@) {
                warn "Invalid value in $$conf{conffile} line $i: $@; parsing aborted";
                return;
            }
        }

        # I don't know how to handle this.
        else {
            warn "Invalid line $i of $$conf{conffile}; parsing aborted";
            return;
        }

        # something changed.
        if ($val_changed_maybe) {

            # determine the name of the event.
            my $eblock = $block eq 'section' ? $name : $block.q(/).$name;

            # fetch the old value and set the new value.
            my $old = $conf->{conf}{$block}{$name}{$key};
            $conf->{conf}{$block}{$name}{$key} = $val;

            # fire the events.
            $conf->fire_events_together(
                [ change                => [ $block, $name ], $key, $old, $val ],
                [ "change:$eblock"      =>                    $key, $old, $val ],
                [ "change:$eblock:$key" =>                          $old, $val ]
            );

        }

    }
    return 1;
}

# returns true if the block is found.
# supports unnamed blocks by get(block, key)
# supports   named blocks by get([block type, block name], key)
sub has_block {
    my ($conf, $block) = @_;
    my ($block_type, $block_name) = _block_parts($block);
    return 1 if $conf->{conf}{$block_type}{$block_name};
}

# returns a list of all the names of a block type.
# for example, names_of_block('listen') might return ('0.0.0.0', '127.0.0.1')
sub names_of_block {
    my ($conf, $block_type) = @_;
    return keys %{ $conf->{conf}{$block_type} };
}

# returns a list of all the keys in a block.
# for example, keys_of_block('modules') would return an array of every module.
# accepts block type or [block type, block name] as well.
sub keys_of_block {
    my ($conf, $block) = @_;
    my ($block_type, $block_name) = _block_parts($block);

    # not a hashref. return empty list.
    my $hashref = $conf->{conf}{$block_type}{$block_name};
    if (!$hashref || !ref $hashref || ref $hashref ne 'HASH') {
        return;
    }

    return keys %$hashref;
}

# returns a list of all the values in a block.
# accepts block type or [block type, block name] as well.
sub values_of_block {
    my ($conf, $block) = @_;
    my ($block_type, $block_name) = _block_parts($block);

    # not a hashref. return empty list.
    my $hashref = $conf->{conf}{$block_type}{$block_name};
    if (!$hashref || !ref $hashref || ref $hashref ne 'HASH') {
        return;
    }

    return values %$hashref;
}

# returns the key:value hash of a block.
# accepts block type or [block type, block name] as well.
sub hash_of_block {
    my ($conf, $block) = @_;
    my ($block_type, $block_name) = _block_parts($block);

    # not a hashref. return empty list.
    my $hashref = $conf->{conf}{$block_type}{$block_name};
    if (!$hashref || !ref $hashref || ref $hashref ne 'HASH') {
        return;
    }

    return %$hashref;
}

# get a configuration value.
# supports unnamed blocks by get(block, key)
# supports   named blocks by get([block type, block name], key)
sub get {
    my ($conf, $block, $key) = @_;
    my ($block_type, $block_name) = _block_parts($block);
    return $conf->{conf}{$block_type}{$block_name}{$key};
}

# remove leading and trailing whitespace.
sub trim {
    my $string = shift;
    $string =~ s/\s+$//;
    $string =~ s/^\s+//;
    return $string;
}

# attach a configuration change listener.
# see notes at top of file for usage.
sub on_change {
    my ($conf, $block, $key, $code, %opts) = @_;
    my ($block_type, $block_name) = _block_parts($block);

    # determine the name of the event.
    $block = $block_type eq 'section' ? $block_name : $block_type.q(/).$block_name;
    my $event_name = "eventedConfiguration.change:$block:$key";

    # register the event.
    return $conf->register_event($event_name => $code, %opts);

}

# handle 'unamed block' or [ 'block type', 'named block' ]
# returns a list (block type, block name)
sub _block_parts {
    my $block = shift;
    if (ref $block && ref $block eq 'ARRAY' && @$block >= 2) {
        return @$block;
    }
    return ('section', $block);
}

1;

=head1 NAME

B<Evented::Configuration> - an event-driven objective configuration class and parser for
Perl software built upon L<Evented::Object>.

=head1 SYNOPSIS

=head2 Example usage

 # create a new configuration instance.
 my $conf = Evented::Configuration->new(conffile => 'etc/some.conf');

 # attach a callback to respond to changes of the user:age key.
 $conf->on_change('user', 'name', sub {
     my ($event, $old, $new) = @_;
     say 'The user\'s age changed from ', $old || '(not born)', "to $new";
 });

 # parse the configuration file.
 $conf->parse_config();

=head2 Example configuration file

 # some.conf file

 # Comments

 # Hello, I am a comment.
 # I am also a comment.

 # Unnamed blocks

 [ someBlock ]

 someKey  = "some string"
 otherKey = 12
 another  = ['hello', 'there']
 evenMore = ['a'..'z']

 # Named blocks

 [ cookies: sugar ]

 favorites = ['sugar cookie', 'snickerdoodle']

 [ cookies: chocolate ]

 favorites = ['chocolate macadamia nut', 'chocolate chip']

=head1 DESCRIPTION

As the name suggests, event firing is what makes Evented::Configuration unique in
comparison to other configuration classes.

=head2 Blocks

Evented::Configuration's configuration is block-styled, with all keys and values
associated with a block. Blocks can be "named," meaning there are several blocks of one
type with different names, or they can be "unnamed," meaning there is only one block of
that type.

=head2 Objective

Evented::Configuration's objective interface allows you to store nothing more than the
configuration object. Then, make the object accessible where you need it.

=head2 Event-driven

Evented::Configuration is based upon the Evented::Object framework, firing events each time
a configuration changes. This allows software to respond immediately to changes of user
settings, etc.

=head2 Convenience

Most configuration parsers spit out nothing more than a hash reference of keys and values.
Evented::Configuration instead supplies several convenient methods for fetching
configuration data.

=head1 METHODS

Evented::Configuration provides several convenient methods for fetching configuration
values.

=head2 Evented::Configuration->new(%options)

Creates a new instance of Evented::Configuration.

 my $conf = Evented::Configuration->new(conffile => 'etc/some.conf');

B<Parameters>

=over 4

=item *

B<options>: a hash of constructor options.

=back

B<%options - constructor options>

=over 4

=item *

* B<conffile>: file location of a configuration file.

=item *

* B<hashref>: I<optional>, a hash ref to store configuration values in.

=back

=head2 $conf->parse_config()

Parses the configuration file. Used also to rehash configuration.

 $conf->parse_config();

=head2 $conf->get($block, $key)

Fetches a single configuration value.

 my $value = $conf->get('unnamedBlock', 'someKey');
 my $other = $conf->get(['blockType', 'namedBlock'], 'someKey');

B<Parameters>

=over 4

=item *

B<block>: for unnamed blocks, should be the string block type. for named blocks, should be
an array reference in the form of C<[block type, block name]>.

=item *

B<key>: the key of the configuration value being fetched.

=back

=head2 $conf->names_of_block($block_type)

Returns an array of the names of all blocks of the specified type.

 foreach my $block_name ($conf->names_of_block('cookies')) {
     print "name of this cookie block: $block_name\n";
 }

B<Parameters>

=over 4

=item *

B<block_type>: the type of the named block.

=back

=head2 $conf->keys_of_block($block)

Returns an array of all the keys in the specified block.

 foreach my $key ($conf->keys_of_block('someUnnamedBlock')) {
     print "someUnnamedBlock unnamed block has key: $key\n";
 }

 foreach my $key ($conf->keys_of_block('someNamedBlock', 'someName')) {
     print "someNamedBlock:someName named block has key: $key\n";
 }

B<Parameters>

=over 4

=item *

B<block>: for unnamed blocks, should be the string block type. for named blocks, should be
an array reference in the form of C<[block type, block name]>.

=back

=head2 $conf->on_change($block, $key, $code, %opts)

Attaches an event listener for the configuration change event. This event will be fired
even if the value never existed. If you want a listener to be called the first time the
configuration is parsed, simply add the listener before calling C<-E<gt>parse_config()>.
Otherwise, add listeners later.

 # an example with an unnamed block
 $conf->on_change('myUnnamedBlock', 'myKey', sub {
     my ($event, $old, $new) = @_;
     ...
 });

 # an example with a name block.
 $conf->on_change(['myNamedBlockType', 'myBlockName'], 'someKey', sub {
     my ($event, $old, $new) = @_;
     ...
 });

 # an example with an unnamed block and ->register_event() options.
 $conf->on_change('myUnnamedBlock', 'myKey', sub {
     my ($event, $old, $new) = @_;
     ...
 }, priority => 100, name => 'myCallback');

B<Parameters>

=over 4

=item *

B<block>: for unnamed blocks, should be the string block type. for named blocks, should be
an array reference in the form of C<[block type, block name]>.

=item *

B<key>: the key of the configuration value being listened for.

=item *

B<code>: a code reference to be called when the value is changed.

=item *

B<opts>: I<optional>, a hash of any other options to be passed to Evented::Object's
C<-E<gt>register_event()>.

=back

=head1 EVENTS

Evented::Configuration fires events when configuration values are changed.

In any case, events are fired with arguments C<(old value, new value)>.

Say you have an unnamed block of type C<myBlock>. If you changed the key C<myKey> in
C<myBlock>, Evented::Configuration would fire the event
C<eventedConfiguration.change:myBlock:myKey>.

Now assume you have a named block of type C<myBlock> with name C<myName>. If you changed
the key C<myKey> in C<myBlock:myName>, Evented::Configuration would fire event
C<eventedConfiguration.change:myBlock/myName:myKey>.

However, it is recommended that you use the C<-E<gt>on_change()> method rather than
directly attaching event callbacks. This will insure compatibility for later versions that
could possibly change the way events are fired.

=head1 SEE ALSO

=over 4

=item *

L<Evented::Object> - the event class that powers Evented::Configuration.

=back

=head1 AUTHOR

L<Mitchell Cooper|https://github.com/cooper> <cooper@cpan.org>

Copyright E<copy> 2014. Released under BSD license.

=over 4

=item *

B<IRC channel>: L<irc.notroll.net #k|irc://irc.notroll.net/k>

=item *

B<Email>: cooper@cpan.org

=item *

B<CPAN>: L<COOPER|http://search.cpan.org/~cooper/>

=item *

B<GitHub>: L<cooper|https://github.com/cooper>

=back

Comments, complaints, and recommendations are accepted. IRC is my preferred communication
medium. Bugs may be reported on
L<RT|https://rt.cpan.org/Public/Dist/Display.html?Name=Evented-Configuration>.
