package POE::Component::IRC::Plugin::IRCDHelp;
BEGIN {
  $POE::Component::IRC::Plugin::IRCDHelp::AUTHORITY = 'cpan:SCILLEY';
}
{
  $POE::Component::IRC::Plugin::VERSION = '0.01';
}

use warnings;
use POE::Component::IRC::Plugin qw( :ALL );

sub PCI_register {
my ( $self, $irc ) = @_;

$irc->plugin_register( $self, 'SERVER', qw( public ) );

return 1;
}

sub PCI_unregister {
my ( $self, $irc ) = @_;

return 1;
}

sub new {

    my $class = shift;
    my $self = {};
    return bless $self, $class;

}

sub _default {
     my ($self, $irc, $event) = splice @_, 0, 3;

     print "Default called for $event\n";

     # Return an exit code
     return PCI_EAT_NONE;
 }

 # Someone asked for help in a chan, return list.
 # Either this isnt loading or something is wrong here
 # When giving the command !help, nothing gets printed to the channel
sub S_public {
     my ($self, $irc) = splice @_, 0, 2;

     # Parameters are passed as scalar-refs including arrayrefs.
     my $nick    = ( split /!/, ${ $_[0] } )[0];
     my $channel = ${ $_[1] }->[0];
     my $msg     = ${ $_[2] };
    
    if (my ($in) = $msg =~ /^!help/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
        # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Hello $nick, Welcome to Help");
    	$irc->yield( privmsg => $channel => "Type !NickServ to get assistance with the Nick Services");
    	$irc->yield( privmsg => $channel => "Type !ChanServ to get assistance with the Channel Services");
    	$irc->yield( privmsg => $channel => "Type !MemoServ to get assistance with the Memo Services");
    	$irc->yield( privmsg => $channel => "Type !ChangeNick to get assistance with Changing Your Nick");
	}
	
	if (my ($in) = $msg =~ /^!NickServ/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
          # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Using Nick Services");
		$irc->yield( privmsg => $channel => "Please type /msg NickServ HELP");
		$irc->yield( privmsg => $channel => "The Nick Service will send you all of it\'s help options");
	}
	
	if (my ($in) = $msg =~ /^!ChanServ/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
          # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Using Channel Services");
		$irc->yield( privmsg => $channel => "Please type /msg ChanServ HELP");
		$irc->yield( privmsg => $channel => "The Channel Service will send you all of it\'s help options");
	}
	
	if (my ($in) = $msg =~ /^!MemoServ/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
          # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Using Memo Services");
		$irc->yield( privmsg => $channel => "Please type /msg MemoServ HELP");
		$irc->yield( privmsg => $channel => "The Memo Service will send you all of it\'s help options");
	}
	
	if (my ($in) = $msg =~ /^!ChangeNick/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
          # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Changing your Nick");
		$irc->yield( privmsg => $channel => "$nick, Changing your Nick is very simple");
		$irc->yield( privmsg => $channel => "just type /nick yournewnick");
		$irc->yield( privmsg => $channel => "EXAMPLE: I want to change my nick to something else");
		$irc->yield( privmsg => $channel => "I would simply type /nick ServerBot  thus using ServerBot as my new nick");
		$irc->yield( privmsg => $channel => "That is all there is to it.");
		
	}
	else {
		$irc->yield( privmsg => $channel => "$nick, I am sorry, I do not understand that command, please type !help");
    	
    	# We don't want other plugins to process this
        return PCI_EAT_PLUGIN;
    }
    
    # Default action is to allow other plugins to process it.
    return PCI_EAT_NONE;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

POE::Component::IRC::Plugin::IRCDHelp - Provides IRCD Server Help

=head1 SYNOPSIS

# A simple IRC Server Help plugin

 package POE::Component::IRC::Plugin::IRCDHelp; 

use warnings;
use POE::Component::IRC::Plugin qw( :ALL );

sub PCI_register {
my ( $self, $irc ) = @_;

$irc->plugin_register( $self, 'SERVER', qw( public ) );

return 1;
}

sub PCI_unregister {
my ( $self, $irc ) = @_;

return 1;
}

sub new {

    my $class = shift;
    my $self = {};
    return bless $self, $class;

}

sub _default {
     my ($self, $irc, $event) = splice @_, 0, 3;

     print "Default called for $event\n";

     # Return an exit code
     return PCI_EAT_NONE;
 }

 # Someone asked for help in a chan, return list.
 # Either this isnt loading or something is wrong here
 # When giving the command !help, nothing gets printed to the channel
sub S_public {
     my ($self, $irc) = splice @_, 0, 2;

     # Parameters are passed as scalar-refs including arrayrefs.
     my $nick    = ( split /!/, ${ $_[0] } )[0];
     my $channel = ${ $_[1] }->[0];
     my $msg     = ${ $_[2] };
    
    if (my ($in) = $msg =~ /^!help/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
        # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Hello $nick, Welcome to Help");
    	$irc->yield( privmsg => $channel => "Type !NickServ to get assistance with the Nick Services");
    	$irc->yield( privmsg => $channel => "Type !ChanServ to get assistance with the Channel Services");
    	$irc->yield( privmsg => $channel => "Type !MemoServ to get assistance with the Memo Services");
    	$irc->yield( privmsg => $channel => "Type !ChangeNick to get assistance with Changing Your Nick");
	}
	
	if (my ($in) = $msg =~ /^!NickServ/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
          # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Using Nick Services");
		$irc->yield( privmsg => $channel => "Please type /msg NickServ HELP");
		$irc->yield( privmsg => $channel => "The Nick Service will send you all of it\'s help options");
	}
	
	if (my ($in) = $msg =~ /^!ChanServ/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
          # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Using Channel Services");
		$irc->yield( privmsg => $channel => "Please type /msg ChanServ HELP");
		$irc->yield( privmsg => $channel => "The Channel Service will send you all of it\'s help options");
	}
	
	if (my ($in) = $msg =~ /^!MemoServ/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
          # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Using Memo Services");
		$irc->yield( privmsg => $channel => "Please type /msg MemoServ HELP");
		$irc->yield( privmsg => $channel => "The Memo Service will send you all of it\'s help options");
	}
	
	if (my ($in) = $msg =~ /^!ChangeNick/) {
         $in =~ tr[a-zA-Z][n-za-mN-ZA-M];
         
          # Print the contents to the channel
		$irc->yield( privmsg => $channel => "Changing your Nick");
		$irc->yield( privmsg => $channel => "$nick, Changing your Nick is very simple");
		$irc->yield( privmsg => $channel => "just type /nick yournewnick");
		$irc->yield( privmsg => $channel => "EXAMPLE: I want to change my nick to something else");
		$irc->yield( privmsg => $channel => "I would simply type /nick ServerBot  thus using ServerBot as my new nick");
		$irc->yield( privmsg => $channel => "That is all there is to it.");
		
	}
	else {
		$irc->yield( privmsg => $channel => "$nick, I am sorry, I do not understand that command, please type !help");
    	
    	# We don't want other plugins to process this
        return PCI_EAT_PLUGIN;
    }
    
    # Default action is to allow other plugins to process it.
    return PCI_EAT_NONE;
}

1;

  

=head1 DESCRIPTION

This Plugin will assist your users if they are new to IRC by providing assistance on NickServ,
ChanServ, MemoServ and Changing their Nick.

This Plugin can be extended simply by adding new commadnds and definitions

=head1 HISTORY

What started out as a learning project for me as I started developing modules for my irc bot
with the assistance of the community, I managed to get this module to work. Now my bot handles
most of the help request that I get on my server.

=head2 USER Commands

!help - get's the main help menu
!NickServ - get's the Nick Services Content
!ChanServ - get's the Channel Services Content
!MemoServ - get's the Memo Services Content
!ChangeNick - Explains how to change their Nick

=head1 SEE ALSO

=head1 SEE ALSO

L<POE::Component::IRC|POE::Component::IRC>

L<Object::Pluggable|Object::Pluggable>

=head1 AUTHOR

Scott Cilley<lt>scott@twistedevolution.net<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut