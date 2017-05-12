# doc_raptor-perl

Perl Wrapper for the [DocRaptor API](https://docraptor.com/documentation).

## Usage

### Code
Make a new DocRaptor client using your API Key:
```perl
my $doc_raptor = DocRaptor->new(api_key => 'YOUR_API_KEY_HERE');
```

Create an options object representing your request parameters:
```perl
my $options = DocRaptor::DocOptions->new(
    document_url  => 'http://example.com',
    is_test       => 1,
    document_type => 'pdf',
    document_name => 'perl-example.pdf'
);
```

Make a request to DocRaptor using the client:
```perl
my $response = $doc_raptor->create($options);
```

The `$response` object is of type `HTTP::Response`, and thus responds to methods like `#code` and `#content`.

You can see a full example, including writing the response to disk at https://github.com/expectedbehavior/doc_raptor-perl/blob/master/script/docraptor_usage.pl.


### Get Help

If you think there is a problem with the Perl library itself, please [create a new issue](https://github.com/expectedbehavior/doc_raptor-perl/issues/new).

If you need help with your document generation, please [contact DocRaptor support](mailto:support@docraptor.com?subject=Perl Help).

Check the [documentation](https://docraptor.com/documentation).


## Development

### Setup
\<version\> below was 5.22.0 for me, but YMMV.
* Install [perlbrew](http://perlbrew.pl/).
* Install (and switch to) perl using perlbrew: `perlbrew install <version> --switch`
* Get a coffee/have a smoke/watch a cartoon while perl installs.
* Install cpanm: `perlbrew install-cpanm`
* (Optional, but recommended) cpanm has the concept of "module sets", so you can create one at this point if you want to isolate this from the rest of your perl module development. The command looks like `perlbrew lib create perl-5.22.0@docraptor`. Then switch to that with `perlbrew switch perl-5.22.0@docraptor`. You can remove all your modules at any time by switching back to the main perl and running `perlbrew lib delete docraptor`
* Install the `Module::Build` module, so you can package and install dependencies: `cpanm --verbose --self-contained --auto-cleanup --install Module::Build`
* Install the project dependencies (requires a modern compiler): `CC=gcc cpanm --installdeps .`
* How's that coffee? Pretty good? Now's the time to really taste the roast.
* Check if it worked – you should have a pdf file "perl-test.pdf" in the project root after: `perl script/docraptor_usage.pl`

Handy commands: `perlbrew list-modules`, `perlbrew available`


### Releasing a New Version
* Update `Build.PL`'s `dist_version` to the new version you want.
* Update `lib/DocRaptor.pm`'s `$PRETTY_VERSION` variable to the new version. Any other files that changed as part of this new version should also have their `$VERSION` updated.
* Update `CHANGELOG.md` to reflect the changes you've made.
* Run `perl ./Build.PL`.
* Run `./Build manifest`.
* Run `./Build disttest`.
* Run `./Build dist`.
* Now you should have a `.tar.gz` file matching your new version. Upload that to the PAUSE site. You can check that the new version has been distributed by checking [CPAN search](http://search.cpan.org/) and searching for "DocRaptor"
