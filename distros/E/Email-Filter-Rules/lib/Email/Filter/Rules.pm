package Email::Filter::Rules;
use strict;
use warnings;
use constant RULE_SPLIT_LIMIT => 3;

our $VERSION =  1.2;

sub new {
    my ( $class, %args ) = @_;
    return unless $args{rules};
    my @rules = ();

    # added the \n check because I got a warning if a did a -e test on
    # a scalar containing newlines
    if ( $args{rules} !~ /\n/s && -e $args{rules} ) {
        open my $fh, '<', $args{rules} or die "Can't open file $args{rules}: $!";
        @rules = <$fh>;
        close $fh;
    }
    elsif ( ref $args{rules} eq 'ARRAY' ) {
        @rules = @{ $args{rules} };
    }
    else {
        @rules = split /\n/, $args{rules};
    }
    return unless scalar @rules;

    my @rule_data = ();

    for my $line (@rules) {
        chomp($line);
        next if $line =~ /^#/;
        my ( $folder, $methods, $substring ) = split( /\s+/, $line, RULE_SPLIT_LIMIT );
        next unless $methods && $folder && $substring;
        my $escaped_substring = quotemeta($substring);
        my @methods = split( /\:/, $methods );
        push @rule_data, {
            methods   => \@methods,
            substring => $escaped_substring,
            folder    => $folder,
        };
    }

    my $obj = {
        rule_data => \@rule_data,
        debug     => $args{debug},
    };

    return bless $obj, $class;
}

sub apply_rules {
    my ( $self, $email ) = @_;
    for my $rule ( @{ $self->{rule_data} } ) {
        for my $method ( @{ $rule->{methods} } ) {
            my $substring = $rule->{substring};
            next unless $email->can($method);
            my $testing = $email->$method;
            next unless $testing;
            warn "testing $method \"$testing\" with $substring\n"
                if $self->{debug};

            # going to keep the 'i' now, may pass this in somehow
            return $rule->{folder} if $testing =~ /$substring/is;
        }
    }
    return;
}

1;

__END__

=head1 NAME

Email::Filter::Rules - Simple Rules for Routing Mail with Email::Filter

=head1 VERSION

1.2

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use Email::Filter;
  use Email::Filter::Rules;

  my $maildir = '/home/jbisbee/mail/';
  my $msg = Email::Filter->new(emergency => $maildir . 'emergency');

  my $mail_lists = Email::Filter::Rules->new(
      rules => '/home/jbisbee/bin/mail_lists'
  );

  if (my $mail_list_folder = $mail_lists->apply_rules($msg)) {
      $msg->accept($maildir . $mail_list_folder);
  }

  $msg->accept($maildir . 'inbox');

Where the 'rules' can be a filename, array ref, or scalar and looks like this

  # DESTINATION FOLDER <space> Email::Filter->$METHOD(S) <space> SUBSTRING
  
  # Linux - FLUX
  lists/linux/flux/linux        to:cc linux@flux.org
  lists/linux/flux/talk         to:cc talk@flux.org
  lists/linux/flux/website      to:cc website@flux.org
  lists/linux/flux/announce     to    flux-announce@flux.org
  
  # Linux - Fluxbox
  lists/linux/fluxbox/users     to:cc fluxbox-users@lists.sourceforge.net
  lists/linux/fluxbox/devel     to:cc fluxbox-devel@lists.sourceforge.net
  lists/linux/fluxbox/announce  to:cc fluxbox-announce@lists.sourceforge.net
  
  # Linux - Debian
  lists/linux/debian/news       to    debian-news@lists.debian.org
  lists/linux/debian/announce   to    debian-announce@lists.debian.org
  lists/linux/debian/mirrors    to    debian-mirrors@lists.debian.org
  lists/linux/debian/bugs       to:cc bugs.debian.org
  
  # Linux - Mozilla
  lists/linux/mozilla-bugs      to    mozilla-bugs
  
  # Perl
  lists/perl/useperl            to:cc use-perl
  
  # Perl - PM
  lists/perl/pm_groups          to:cc pm_groups@pm.org
  lists/perl/pm/southflorida    to:cc southflorida-pm@mail.pm.org
  
  # Word of the Day
  lists/word-of-the-day from word@m-w.com

=head1 DESCRIPTION

Email::Filter::Rules is a simple way to route e-mail into folders without
having to touch your filter script.  I used to edit my filter script 
often to add or remove e-mail lists and often would fat finger something
and enter a typo.  This would result in all my e-mail bouncing and all in
all would be a real bummer.

I wanted to make it syntax simple so it wouldn't end up looking like to awful
procmail recipe or some cryptic piece of junk.

=head1 USAGE

Simply put, a rule consists of a destination folder, one to many Email::Filter 
method names, and a substring to test the result of the method call.

  DESTINATION FOLDER <space> Email::Filter->$METHOD(S) <space> SUBSTRING

where a rule looks like this

  lists/perl/pm/southflorida    to:cc southflorida-pm@mail.pm.org

each rule is tested and quotemeta is used on the substring

  $msg->to =~ /southflorida-pm\@mail\.pm\.org/i
  $msg->cc =~ /southflorida-pm\@mail\.pm\.org/i

and the destination folder is returned for the first matching test

  lists/perl/pm/southflorida

and now I have the mail folder, I can tell the Email::Filter object to accept 
to that folder.

So thats it, short, simple, and to the point.  No more boucing e-mails by 
editing my filter directly. :)

=head1 CONSTRUCTOR

=head2 Email::Filter::Rules->new( rules => $rules )

=over 4

=item * rules

Can be a scalar, array reference, or a file name name.

=item * debug

Boolean to turn on warnings during apply_rules

=back

=head1 METHODS

=head2 $efr->apply_rules( $email )

Pass in an e-mail object and attempt to call methods you defined in your
rules file on it.

=head1 AUTHOR

Copyright 2005 Jeff Bisbee <jbisbee@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with 
this module.

=head1 SEE ALSO

L<Email::Filter>, L<Email::Simple>

