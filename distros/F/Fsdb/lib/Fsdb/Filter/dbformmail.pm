#!/usr/bin/perl

#
# dbformmail.pm
# Copyright (C) 1997-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbformmail;

=head1 NAME

dbformmail - write a shell script that will send e-mail to many people

=head1 SYNOPSIS

dbformmail [-m MECHANISM] format_file.txt

=head1 DESCRIPTION

Read a ``form mail'' message from the file FORMAT_FILE.TXT,
filling in underscore-preceded column-names with data.
Output a shell script which will send each message through some
mail transport MECHANISM.

Do not use this program for evil or I will have to come over
and have words with you.

Note that this program does NOT actually SEND the mail. 
It writes a shell script that will send the mail for you.
I recommend you save it to a file, check it (one last time!),
then run it with sh.

Unlike most Fsdb programs, this program does I<not> output a FSDB file.

=head1 OPTIONS

=over 4

=item B<-m MECHANISM>

Select the mail-sending mechanism: Mail, sendmail, or mh.
Defaults to "Mail".

Mail uses a Berkeley-style /usr/bin/Mail.
Sendmail invokes /usr/bin/sendmail.
Mh writes messages into the current directory, treating it
as an mh-style mailbox (one message per file, with filesnames as sequential
integrates).


=back

=for comment
begin_standard_fsdb_options

This module also supports the standard fsdb options:

=over 4

=item B<-d>

Enable debugging output.

=item B<-i> or B<--input> InputSource

Read from InputSource, typically a file name, or C<-> for standard input,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<-o> or B<--output> OutputDestination

Write to OutputDestination, typically a file name, or C<-> for standard output,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<--autorun> or B<--noautorun>

By default, programs process automatically,
but Fsdb::Filter objects in Perl do not run until you invoke
the run() method.
The C<--(no)autorun> option controls that behavior within Perl.

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 SAMPLE USAGE

=head2 Input:

    #fsdb account passwd uid gid fullname homedir shell
    johnh * 2274 134 John_Heidemann /home/johnh /bin/bash
    greg * 2275 134 Greg_Johnson /home/greg /bin/bash
    root * 0 0 Root /root /bin/bash
    # this is a simple database

Sample form (in the file form.txt):

    To: _account
    From: the sysadmin <root>
    Subject: time to change your password

    Please change your password regularly.
    Doesn't this message make you feel safer?


=head2 Command:

    cat DATA/passwd.fsdb | dbformmail form.txt >outgoing.sh

=head2 Output (in outgoing.sh):

    #!/bin/sh
    sendmail 'johnh' <<'END'
    To: johnh
    From: the sysadmin <root>
    Subject: time to change your password
    
    Please change your password regularly.
    Doesn't this message make you feel safer?

    END
    sendmail 'greg' <<'END'
    (etc.)

And to send the mail, run

    sh outgoing.sh

=head1 SEE ALSO

L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;


=head2 new

    $filter = new Fsdb::Filter::dbformmail(@arguments);

Create a new dbformmail object, taking command-line arguments.

=cut

sub new ($@) {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    $self->set_defaults;
    $self->parse_options(@_);
    $self->SUPER::post_new();
    return $self;
}


=head2 set_defaults

    $filter->set_defaults();

Internal: set up defaults.

=cut

sub set_defaults ($) {
    my($self) = @_;
    $self->SUPER::set_defaults();
    $self->{_mechanism} = 'Mail';
    $self->{_format_file} = undef;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse command-line arguments.

=cut

sub parse_options ($@) {
    my $self = shift @_;

    my(@argv) = @_;
    $self->get_options(
	\@argv,
 	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'm|mechanism=s' => \$self->{_mechanism},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    if ($#argv >= 0) {
	croak($self->{_prog} . ": format file already defined as " . $self->{_format_file} . "\n")
	    if (defined($self->{_format_file}));
	$self->{_format_file} = $argv[0];
    };
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    croak($self->{_prog} . ": unknown mail mechanism $self->{_mechanism}.\n")
	if (!($self->{_mechanism} eq 'Mail' || $self->{_mechanism} eq 'sendmail' || $self->{_mechanism} eq 'mh'));
    croak($self->{_prog} . ": no format file specified.\n")
	if (!defined($self->{_format_file}));

    $self->finish_io_option('input', -comment_handler => $self->create_delay_comments_sub);
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    #
    # Read the form.
    #
    open(FORM, "<" . $self->{_format_file})
	or croak($self->{_prog} . ": cannot open " . $self->{_format_file} . ".\n");
    my @form = ();
    while (<FORM>) {
	s/\@/\\\@/g;   # quote @'s
	push(@form, $_);
    };
    close FORM;

    croak($self->{_prog} . ": no To: line in form.\n")
	if (!grep(/^To:/i, @form));

    # find an end-of-form marker
    my($end_of_form_marker) = undef;
    foreach my $try (qw(END END2378END END_99243_END)) {
	my(@hits) = grep(/^$try$/, @form);
	if ($#hits == -1) {
	    $end_of_form_marker = $try;
	    last;
	};
    };
    croak($self->{_prog} . ": cannot find an end-of-form marker that's not already in the data.\n")
        if (!defined($end_of_form_marker));

    #
    # Generate the code.
    #
    my($code) = $self->{_in}->codify("<<$end_of_form_marker;\n" . join("", @form) . "$end_of_form_marker\n");
    print $code if ($self->{_debug});

    #
    # Do it.
    #
    my $fref;
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    print "#!/bin/sh\n" if ($self->{_mechanism} ne 'mh');
    my $mh_seqno = 1;
    
    while ($fref = &$read_fastpath_sub()) {
	my $result = eval $code;
	$@ && croak($self->{_prog} . ": internal eval error ``$@''.\n");

	# This is not a very elegant to extract the destination.  :-<
	my(@field_names) = qw(to cc subject);
	my($field_regexp) = '(' . join("|", @field_names) . ')';
	my(%fields);
	my($in_body) = undef;
	my $result_body = '';
	foreach (split(/\n/, $result)) {
	    if ($in_body) {
		$result_body .= "$_\n";
		next;
	    };
	    if (/^\s*$/) {
		# blank line terminates header
		$in_body = 1;
		next;  
	    };
	    if (/^$field_regexp:\s*(.*)$/i) {
		my($key, $value) = (lc($1), $2);
		croak($self->{_prog} . ": duplicate fields not supported, field: $key.\n")
		    if (defined($fields{$key}));
		$fields{$key} = $value;
	    };
	};
	croak($self->{_prog} . ": to missing.\n")
	    if (!defined($fields{'to'}));

	# Quote single quotes in $to.
	foreach (keys %fields) {
	    $fields{$_} =~ s/\'/\'\\\'\'/g;
	};

	if ($self->{_mechanism} eq 'sendmail') {
	    print "sendmail '" . $fields{"to"} . "' <<'$end_of_form_marker'\n$result\n$end_of_form_marker\n\n";
	} elsif ($self->{_mechanism} eq 'Mail') {
	    my $cc_arg = (defined($fields{"cc"}) ? "-c '" . $fields{"cc"} . "' " : "");
	    my $subject_arg = (defined($fields{"subject"}) ? "-s '" . $fields{"subject"} . "' " : "");
	    print "Mail $subject_arg $cc_arg '" . $fields{"to"} . "' <<'$end_of_form_marker'\n$result_body\n$end_of_form_marker\n\n";
	} elsif ($self->{_mechanism} eq 'mh') {
            my ($mh_try_count) = 0;
            while (-f $mh_seqno) {
                $mh_seqno++;
                croak $self->{_prog} . ": tried to create 1000 mh files but they already existed, giving up.\n" if (++$mh_try_count > 1000);
            };
            open(MH_FILE, ">$mh_seqno") || croak $self->{_prog} . ": could not create file $mh_seqno.\n";
            print MH_FILE $result;
            close MH_FILE;
            $mh_seqno++;
	} else {
	    croak($self->{_prog} . ": unknown mechanism " . $self->{_mechanism} . ".\n");
	};
    };
};


=head2 finish

    $filter->finish();

Internal: write trailer, but no trailer for us.

=cut
sub finish ($) {
    my($self) = @_;

    if (defined($self->{_delay_comments})) {
	foreach (@{$self->{_delay_comments}}) {
	    $_->flush(undef);
	};
    };
    print "# " . $self->compute_program_log() . "\n";
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
