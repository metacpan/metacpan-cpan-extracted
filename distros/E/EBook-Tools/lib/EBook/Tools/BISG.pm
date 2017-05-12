package EBook::Tools::BISG;
use warnings; use strict; use utf8;
use 5.010;
use version 0.74; our $VERSION = qv("0.5.4");

=head1 NAME

EBook::Tools::BISG - Class for downloading information from the Book Industry Study Group webpages

=head1 SYNOPSIS

 use EBook::Tools::BISG;
 my $bisg = EBook::Tools::BISG->new();
 $bisg->download_bisac;
 $bisg->save_bisac;
 say $bisg->bisac('fic000000');
 %bisac_codes = $bisg->bisac();

=head1 DEPENDENCIES

=over

=item * C<DBI>

This will also require a DBD of your choice.  The default is to use a
local SQLite store.

=item * C<LWP>

=item * C<Mojo::DOM>

=back

=cut

use Carp;
use DBI;
use EBook::Tools qw(:all);
use LWP;
use Mojo::DOM;


#################################
########## CONSTRUCTOR ##########
#################################

=head1 CONSTRUCTOR

=head2 C<new(%args)>

Instantiates a new Ebook::Tools::BISG object.

=head3 Arguments

=over

=item * C<baseurl>

The base url of the bisg.org website or mirror to use.

=item * C<dsn>

The Perl::DBI Data Source Name.  Defaults to a sqlite store named
bisac.sqlite in the user config directory.

=back

=cut

my @fields = (
    'baseurl',
    'bisac_codes',
    'dbuser',
    'dbpass',
    'dsn',
    );

require fields;
fields->import(@fields);

sub new {
    my ($self,%args) = @_;
    my $class = ref($self) || $self;
    my $subname = (caller(0))[3];
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'baseurl' => 1,
        'dbuser'  => 1,
        'dbpass'  => 1,
        'dsn'     => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
          if(!$valid_args{$arg});
    }

    $self = fields::new($class);
    $self->{baseurl} = $args{file} || 'http://www.bisg.org';
    $self->{bisac_codes} = {};
    $self->{dbuser} = $args{dbuser} || '';
    $self->{dbpass} = $args{dbpass} || '';

    if($args{dsn}) {
        $self->{dsn} = $args{dsn};
        $self->load_bisac();
    }
    else {
        my $configdir = userconfigdir();
        if($configdir) {
            $self->{dsn} = 'dbi:SQLite:dbname=' . $configdir . '/bisac.sqlite';
            $self->load_bisac();
        }
    }

    return $self;
}


=head1 ACCESSOR METHODS

=head2 C<bisac($code)>

Returns either the name matching a particular code (case-insensitive),
or the hash of all BISAC codes and references with the keys in
lower-case if no argument is provided.

=cut

sub bisac :method
{
    my ($self,$code) = @_;
    my $subname = ( caller(0) )[3];

    if ($code) {
        return $self->{bisac_codes}->{$code};
    }
    return %{$self->{bisac_codes}};
}


=head2 C<find($regexp)>

Returns a list of all BISAC values (names) where either the key or the
value for that entry matches a case-insensitive regular expression.
If no argument is specified, or it is just '.', then the entire list
is returned.

=cut

sub find :method
{
    my ($self,$regexp) = @_;
    my $subname = ( caller(0) )[3];

    my %seen;
    my @keys;

    # Create a list of all unique keys and values (lowercased to be
    # used again as keys)
    foreach my $key (keys %{$self->{bisac_codes}}) {
        $seen{$key} = 1;
    }
    foreach my $value (values %{$self->{bisac_codes}}) {
        $seen{lc $value} = 1;
    }

    if(not $regexp or $regexp eq '.') {
        @keys = sort keys %seen;
    }
    else {
        @keys = sort grep { /$regexp/i } keys %seen;
    }

    return @{$self->{bisac_codes}}{@keys};
}


=head1 MODIFIER METHODS

=head2 C<download_bisac()>

Downloads the BISAC codes from the BISG website and converts them into
a hash.  Codes and obsolete entries are lowercased and made the keys,
the values will be the official names they map to.

=cut

sub download_bisac :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];

    # LWP/Cookies variables
    my $browser = LWP::UserAgent->new;
    my $content;
    my $content_type;
    my $response;
    my $url;

    # HTML parsing
    my $dom = Mojo::DOM->new();
    my @elements;
    my $category;
    my $key;
    my $value;
    my $bisac_headings_top_url =
      $self->{baseurl} . '/complete-bisac-subject-headings-2013-edition';

    debug(2,"DEBUG[",$subname,"]");


    $response = $browser->get($bisac_headings_top_url);
    croak "Error loading ${bisac_headings_top_url}: ", $response->status_line()
      unless $response->is_success();
    $content_type = $response->content_type();
    $content = $response->content();

    $dom->parse($content);

    foreach my $link ($dom->find('a[href*="bisac-subject-headings-list-"]')->each) {
        my $href = $link->attr('href');
        my $url = $self->{baseurl} . $href;
        $response = $browser->get($url);
        croak "Error loading ${url}: ", $response->status_line()
          unless $response->is_success();
        $content_type = $response->content_type();
        $content = $response->content();

        $dom->parse($content);

        $category = uc $dom->at('h3')->text;
        say "parsing ${category}...";

        foreach my $tr ($dom->find('tr')->each) {
            my $td = $tr->children('td');
            if ($td->[1] and $td->[1] =~ /\w/) {
                $key = $td->[0]->all_text;
                if ($key =~ /\w/) {
                    $value = $td->[1]->all_text;
                }
                else {
                    # The first column is empty, but the second column
                    # is not.  This indicates a non-code reference
                    # entry.
                    #
                    # If the second column does not contain ' see ',
                    # then we don't know how to parse the reference,
                    # and we skip.  If it contains ' see ' and ' or '
                    # then the reference is ambiguous and we also
                    # skip.
                    #
                    # If it contains 'headings under' then the result
                    # is ambiguous and we must skip.
                    #
                    # Otherwise the portion before ' see ' becomes the
                    # key and the portion afterwards becomes the
                    # value.

                    if ($td->[1]->all_text =~
                          /^				# Start of string
                           (?! .* headings \s under)	# Not matching look-ahead 'headings under'
                           (.*?) \s see \s		# Match all characters up to ' see '
                           ( (?:(?! \s or \s )		# Complex match not matching ' or '
                                   .)*)			# ... but matching anything else
                          /x) {

                        $key = $1;
                        $value = $2;

                        # The value won't have the category prefix if
                        # it's in the current category, so we need to
                        # check and prepend if necessary.
                        if ($value !~ /^[A-Z]{3}/x) {
                            $value = $category . ' / ' . $value;
                        }
                    }
                    else {
                        $key = '';
                        $value = '';
                    }
                }
                # Remove trailing parentheticals and asterisks
                $value =~ s/(.*?) \(.*\)/$1/;
                $value =~ s/(.*?) \*/$1/;

                if($key and $value) {
                    $key = lc $key;
                    $self->{bisac_codes}->{$key} = $value;

                    # Also put in a self-mapping of the lowercased
                    # value to itself if one does not already exist.
                    if (! $self->{bisac_codes}->{lc $value}) {
                        $self->{bisac_codes}->{lc $value} = $value;
                    }
                }
            }
            else {
                # There is one row with a single <td> element at the
                # very end.  We ignore this.
            }
        }
    }
    return;
}


=head2 C<load_bisac()>

Load the BISAC codes from the specified database into the hash.  This
is called automatically by new().

If the load fails, nothing will happen (silently!), so the only way to
tell is to check to see if you have a populated hash afterwards.

=cut

sub load_bisac :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];

    my $dsn = $self->{dsn};
    my $sql;

    my $dbh = DBI->connect(
        $self->{dsn},$self->{dbuser},$self->{dbpass}, {
            AutoCommit => 0,
            PrintError => 0,
            RaiseError => 0,
            sqlite_see_if_its_a_number => 1,
        });
    return unless $dbh;

    my $sth;
    my $row;

    $sth = $dbh->prepare('SELECT code,name FROM bisac_codes');
    if (! $sth) {
        # Table doesn't exist
        $dbh->disconnect;
        return;
    }
    $sth->execute() or croak ("Failed to load BISAC codes from database");
    while($row = $sth->fetchrow_arrayref) {
        $self->{bisac_codes}->{$row->[0]} = $row->[1];
    }

    $dbh->disconnect();

    return;
}


=head2 C<save_bisac()>

Save the BISAC codes in the hash to the database.  This will destroy
any existing table named bisac_codes.

Croaks on failure.

=cut

sub save_bisac :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];

    my $dbh = DBI->connect(
        $self->{dsn},$self->{dbuser},$self->{dbpass}, {
            AutoCommit => 0,
            PrintError => 0,
            RaiseError => 1,
            sqlite_see_if_its_a_number => 1,
        })
      or croak("Failed to connect to $self->{dsn}");

    my $sth;
    my $sql;
    my @fields;
    my $fieldlist;
    my $placeholders;

    # Ensure the bisac_codes table exists as a blank slate.
    $dbh->{RaiseError} = 0;
    $sth = $dbh->prepare('SELECT * FROM bisac_codes WHERE 0 = 1');
    $dbh->{RaiseError} = 1;
    if ($sth) {
        $dbh->do('DROP TABLE bisac_codes');
    }

    $sql = '
      CREATE TABLE bisac_codes (
        code	text	PRIMARY KEY,
        name	text,
        comment	text
      );';
    $sth = $dbh->do($sql)
      or croak ("Failed to create bisac_codes table!");
    $dbh->commit();

    @fields = ('code','name');
    $fieldlist = join (', ',@fields);
    $placeholders = join (', ', map {'?'} @fields);
    $sth = $dbh->prepare("INSERT INTO bisac_codes (${fieldlist}) VALUES (${placeholders})");
    foreach my $key (keys %{$self->{bisac_codes}}) {
        $sth->execute($key,$self->{bisac_codes}->{$key});
    }
    $dbh->commit;
    $dbh->disconnect;

    return;
}

1;
__END__
