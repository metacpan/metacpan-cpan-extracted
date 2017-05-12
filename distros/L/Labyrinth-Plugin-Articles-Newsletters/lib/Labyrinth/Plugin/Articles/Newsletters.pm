package Labyrinth::Plugin::Articles::Newsletters;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.00';

=head1 NAME

Labyrinth::Plugin::Articles::Newsletters - Newsletters plugin handler for Labyrinth

=head1 DESCRIPTION

Contains all the article handling functionality for Newsletters.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Articles);

use Labyrinth::Audit;
use Labyrinth::DTUtils;
use Labyrinth::Mailer;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

use Encode qw/encode decode/;
use Session::Token;

# -------------------------------------
# Variables

our $LEVEL      = EDITOR;
my $LEVEL2      = ADMIN;

# sectionid is used to reference different types of articles,
# however, the default is also a standard article.
my $NEWSLETTERS = 12;

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    articleid   => { type => 0, html => 0 },
    title       => { type => 1, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my %email_fields = (
    name    => { type => 1, html => 1 },
    email   => { type => 1, html => 1 },
    resend  => { type => 0, html => 1 },
);

my (@email_man,@email_all);
for(keys %email_fields) {
    push @email_man, $_     if($email_fields{$_}->{type});
    push @email_all, $_;
}

my %code_fields = (
    id      => { type => 1, html => 1 },
    code    => { type => 1, html => 1 },
);

my (@code_man,@code_all);
for(keys %code_fields) {
    push @code_man, $_     if($code_fields{$_}->{type});
    push @code_all, $_;
}

my %subs_fields = (
    subscriptions   => { type => 1, html => 1 },
);

my (@subs_man,@subs_all);
for(keys %subs_fields) {
    push @subs_man, $_     if($subs_fields{$_}->{type});
    push @subs_all, $_;
}

my %send_fields = (
    hFrom       => { type => 1, html => 1 },
    hSubject    => { type => 1, html => 1 },
);

my (@send_man,@send_all);
for(keys %send_fields) {
    push @send_man, $_     if($send_fields{$_}->{type});
    push @send_all, $_;
}

my $gen = Session::Token->new(length => 24);

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Section

Sets for Newsletter Articles within the system.

=item Subscribe

Single user subscription process. To be used by users who wish to sign up to 
the newsletters. Starts the subscription process. 

=item Subscribed

Last part of the subscription process.

=item UnSubscribe

Single user unsubscription process. To be used by users who have previously 
signing up for the newsletters. Starts the unsubscription process. 

=item UnSubscribed

Last part of the unsubscription process.

=back

=cut

sub Section {
    $cgiparams{sectionid} = $NEWSLETTERS;
}

sub Subscribe {
    # requires: name, email
    for(keys %email_fields) {
           if($email_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}); }
        elsif($email_fields{$_}->{html} == 2) { $cgiparams{$_} =  SafeHTML($cgiparams{$_}); }
    }

    return  if FieldCheck(\@email_all,\@email_man);

    # already exists?
    my @email = $dbi->GetQuery('hash','CheckSubscptionEmail',$tvars{data}{email});
    if(@email && !$tvars{data}{resend}) {
        $tvars{resend} = 1;
        $tvars{sub}{email} = $tvars{data}{email};
        $tvars{sub}{name} = $tvars{data}{name};
        return;
    }

    my $code = $gen->get();
    my $subscriptionid;

    if(@email) {
        $subscriptionid = $email[0]->{subscriptionid};
        $dbi->DoQuery('UpdateUnConfirmedEmail',$tvars{data}{email},$code,$subscriptionid);
    } else {
        $subscriptionid = $dbi->IDQuery('InsertSubscriptionEmail',$tvars{data}{name},$tvars{data}{email},$code);
    }

    MailSend(   template        => '',
                name            => $tvars{data}{name},
                recipient_email => $tvars{data}{email},
                code            => "$code/$subscriptionid",
                webpath         => "$tvars{docroot}$tvars{webpath}",
                nowrap          => 1
    );

    if(!MailSent()) {
        $tvars{failure} = 1;
    } else {
        $tvars{success} = 1;
    }
}

sub Subscribed {
    # requires: keycode, id
    for(keys %code_fields) {
           if($code_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}); }
        elsif($code_fields{$_}->{html} == 2) { $cgiparams{$_} =  SafeHTML($cgiparams{$_}); }
    }

    return  if FieldCheck(\@code_all,\@code_man);

    my @email = $dbi->GetQuery('hash','CheckSubscriptionKey',$tvars{data}{code},$tvars{data}{id});
    if(@email) {
        $dbi->DoQuery('ConfirmedSubscription',$tvars{data}{id});
        $tvars{success} = 1;
    }
}

sub UnSubscribe {
    # requires: email
    return  unless($cgiparams{email});

    # doesn't exist?
    my @email = $dbi->GetQuery('hash','CheckSubscptionEmail',$cgiparams{email});
    return  unless(@email);

    $dbi->DoQuery('RemoveSubscription',$email[0]->{subscriptionid});
    $tvars{success} = 1;
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item AdminSubscription

List current subscriptions.

=item BulkSubscription

Add bulk email subscriptions.

=item DeleteSubscription

Delete email subscriptions.

=item PrepareNewsletter

Prepares the selected newseletter and subscriber list.

=item SendNewsletter

Sends out the selected newseletter to the selected subscriber list.

=back

=cut

sub AdminSubscription {
    my $self = shift;

    return  unless AccessUser($LEVEL);

    if($cgiparams{doaction}) {
        $self->DeleteSubscription() if($cgiparams{doaction} eq 'Delete');
    }

    my @emails = $dbi->GetQuery('hash','ListSubscptions');
    $tvars{data} = \@emails   if(@emails);
}

sub BulkSubscription {
    return  unless AccessUser($LEVEL);

    # requires: subscriptions
    for(keys %subs_fields) {
           if($subs_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}); }
        elsif($subs_fields{$_}->{html} == 2) { $cgiparams{$_} =  SafeHTML($cgiparams{$_}); }
    }

    return  if FieldCheck(\@subs_all,\@subs_man);
    my @subs = split(qr/\s+/,$tvars{data}{subscriptions});
    for my $sub (@subs) {
        my ($name,$email) = split(',',$sub);

        # already exists?
        my @email = $dbi->GetQuery('hash','CheckSubscptionEmail',$email);
        if(@email) {
            $dbi->DoQuery('UpdateConfirmedEmail',$name,'',$email[0]->{subscriptionid});
        } else {
            $dbi->IDQuery('InsertSubscriptionEmail',$name,$email,'');
        }
    }
}

sub DeleteSubscription {
    return  unless AccessUser($LEVEL);
    
    my @ids = CGIArray('LISTED');
    $dbi->DoQuery('RemoveSubscription',$_)  for(@ids);
}

sub PrepareNewsletter {
    return  unless AccessUser($LEVEL);
    my @emails = $dbi->GetQuery('hash','GetSubscribers');
    $tvars{data} = \@emails   if(@emails);
}

sub SendNewsletter {
    return  unless AccessUser($LEVEL);

    for(keys %send_fields) {
           if($send_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}); }
        elsif($send_fields{$_}->{html} == 2) { $cgiparams{$_} =  SafeHTML($cgiparams{$_}); }
    }

    return  if FieldCheck(\@send_all,\@send_man);

    # ensure we have a newsletter
    return  unless AuthorCheck('GetArticleByID','articleid',$LEVEL);

    my %opts = (
        text    => 'mailer/newsletter.txt',
        html    => 'mailer/newsletter.html',
        nowrap  => 1,
        from    => $tvars{data}{hFrom},
        subject => $tvars{data}{hSubject}
    );

    my @id = CGIArray('LISTED');
    $tvars{gotusers} = scalar(@id);
    $tvars{mailsent} = 0;

    for my $id (@id) {
        my @users = $dbi->GetQuery('hash','CheckSubscriptionKey','',$id);
        next    unless(@users);
        my $user = $users[0];
        $user->{name} = encode('MIME-Q', decode('MIME-Header', $user->{name}));

        $opts{body}             = $tvars{data}{body};
        $opts{vars}             = \%tvars;
        $opts{edate}            = formatDate(16);
        $opts{email}            = $user->{email};
        $opts{recipient_email}  = $user->{email};
        $opts{ename}            = $user->{name} || '';
        $opts{mname}            = $user->{name};

        for my $key (qw(from subject body)) {
            $opts{$key} =~ s/ENAME/$user->{name}/g;
            $opts{$key} =~ s/EMAIL/$user->{email}/g;
            $opts{$key} =~ s/\r/ /g;    # a bodge
        }

#use Data::Dumper;
#LogDebug("opts=".Dumper(\%opts));
        HTMLSend(%opts);
        $dbi->DoQuery('InsertNewsletterIndex',$cgiparams{articleid},$user->{subscriptionid},time());

        # if sent update index
        $tvars{mailsent}++  if(MailSent());
    }

    $tvars{thanks} = $tvars{mailsent} ? 2 : 3;
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
