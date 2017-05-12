# NAME

Google::BigQuery - Google BigQuery Client Library for Perl

# SYNOPSIS

    use Google::BigQuery;

    my $client_email = <YOUR CLIENT EMAIL ADDRESS>;
    my $private_key_file = <YOUR PRIVATE KEY FILE>;
    my $project_id = <YOUR PROJECT ID>;

    # create a instance
    my $bq = Google::BigQuery::create(
      client_email => $client_email,
      private_key_file => $private_key_file,
      project_id => $project_id,
    );

    # create a dataset
    my $dataset_id = <YOUR DATASET ID>;
    $bq->create_dataset(
      dataset_id => $dataset_id
    );
    $bq->use_dataset($dataset_id);

    # create a table
    my $table_id = 'sample_table';
    $bq->create_table(
      table_id => $table_id,
      schema => [
        { name => "id", type => "INTEGER", mode => "REQUIRED" },
        { name => "name", type => "STRING", mode => "NULLABLE" }
      ]
    );

    # load
    my $load_file = "load_file.tsv";
    open my $out, ">", $load_file or die;
    for (my $id = 1; $id <= 100; $id++) {
      if ($id % 10 == 0) {
        print $out join("\t", $id, undef), "\n";
      } else {
        print $out join("\t", $id, "name-${id}"), "\n";
      }
    }
    close $out;

    $bq->load(
      table_id => $table_id,
      data => $load_file,
    );
      
    unlink $load_file;

    # insert
    my $values = [];
    for (my $id = 101; $id <= 103; $id++) {
      push @$values, { id => $id, name => "name-${id}" };
    }
    $bq->insert(
      table_id => $table_id,
      values => $values,
    );

    # The first time a streaming insert occurs, the streamed data is inaccessible for a warm-up period of up to two minutes.
    sleep(120);

    # selectrow_array
    my ($count) = $bq->selectrow_array(query => "SELECT COUNT(*) FROM $table_id");
    print $count, "\n"; # 103

    # selectall_arrayref
    my $aref = $bq->selectall_arrayref(query => "SELECT * FROM $table_id ORDER BY id");
    foreach my $ref (@$aref) {
      print join("\t", @$ref), "\n";
    }

    # drop table
    $bq->drop_table(table_id => $table_id);

    # drop dataset
    $bq->drop_dataset(dataset_id => $dataset_id);

# DESCRIPTION

Google::BigQuery - Google BigQuery Client Library for Perl

# INSTALL

    cpanm Google::BigQuery

If such a following error occurrs,

    --> Working on Crypt::OpenSSL::PKCS12
    Fetching http://www.cpan.org/authors/id/D/DA/DANIEL/Crypt-OpenSSL-PKCS12-0.7.tar.gz ... OK
    Configuring Crypt-OpenSSL-PKCS12-0.6 ... N/A
    ! Configure failed for Crypt-OpenSSL-PKCS12-0.6. See /home/vagrant/.cpanm/work/1416208473.2527/build.log for details.

For now, you can work around it as below.

    # cd workdir
    cd /home/vagrant/.cpanm/work/1416208473.2527/Crypt-OpenSSL-PKCS12-0.7
    rm -fr inc
    cpanm Module::Install

    ### If you are a Mac user, you might also need the following steps.
    #
    # 1. Install new OpenSSL library and header.
    # brew install openssl
    #
    # 2. Add a lib_path and a includ_path to the Makefile.PL.
    # --- Makefile.PL.orig    2013-12-01 07:41:25.000000000 +0900
    # +++ Makefile.PL 2014-11-18 11:58:39.000000000 +0900
    # @@ -17,8 +17,8 @@
    #
    #  requires_external_cc();
    #
    # -cc_inc_paths('/usr/include/openssl', '/usr/local/include/ssl', '/usr/local/ssl/include');
    # -cc_lib_paths('/usr/lib', '/usr/local/lib', '/usr/local/ssl/lib');
    # +cc_inc_paths('/usr/local/opt/openssl/include', '/usr/include/openssl', '/usr/local/include/ssl', '/usr/local/ssl/include');
    # +cc_lib_paths('/usr/local/opt/openssl/lib', '/usr/lib', '/usr/local/lib', '/usr/local/ssl/lib');
    
    perl Makefile.PL
    make
    make test
    make install

# METHODS

See details of option at https://cloud.google.com/bigquery/docs/reference/v2/.

- create

    Create a instance.

        my $bq = Google::BigQuery::create(
          client_email => $client_email,            # required
          private_key_file => $private_key_file,    # required
          project_id => $project_id,                # optional
          dataset_id => $dataset_id,                # optional
          scope => \@scope,                         # optional (default is 'https://www.googleapis.com/auth/bigquery')
          version => $version,                      # optional (only 'v2')
        );

- use\_project

    Set a default project.

        $bq->use_project($project_id);

- use\_dataset

    Set a default dataset.

        $bq->use_dataset($dataset_id);

- create\_dataset

    Create a dataset.

        $bq->create_dataset(              # return 1 (success) or 0 (error)
          project_id => $project_id,      # required if default project is not set
          dataset_id => $dataset_id,      # required if default dataset is not set
          access => \@access,             # optional
          description => $description,    # optional
          friendlyName => $friendlyName,  # optional
        );

- drop\_dataset

    Drop a dataset.

        $bq->drop_dataset(              # return 1 (success) or 0 (error)
          project_id => $project_id,    # required if default project is not set
          dataset_id => $dataset_id,    # required
          deleteContents => $boolean,   # optional
        );

- show\_datasets

    List datasets.

        $bq->show_datasets(             # return array of dataset_id
          project_id => $project_id,    # required if default project is not set
          all => $boolean,              # optional
          maxResults => $maxResults,    # optional
          pageToken => $pageToken,      # optional
        );

    Use get\_nextPageToken() if you want to use pageToken.

        $bq->show_datasets(maxResults => 1);
        my $nextPageToken = $bq->get_nextPageToken;
        $bq->show_datasets(maxResults => 1, nextPageToken => $nextPageToken);

- desc\_dataset

    Describe a dataset.
    This method returns a Datasets resource.
    See datails of a Datasets resource at https://cloud.google.com/bigquery/docs/reference/v2/datasets#resource.

        $bq->desc_dataset(              # return hashref of datasets resource
          project_id => $project_id,    # required if default project is not set
          dataset_id => $dataset_id,    # required if default project is not set
        );

- create\_table

    Create a table.

        $bq->create_table(                    # return 1 (success) or 0 (error)
          project_id => $project_id,          # required if default project is not set
          dataset_id => $dataset_id,          # required if default project is not set
          table_id => $table_id,              # required
          description => $description,        # optional
          expirationTime => $expirationTime,  # optional
          friendlyName => $friendlyName,      # optional
          schema => \@schma,                  # optional
          view => $query,                     # optional
        );

- drop\_table

    Drop a table.

        $bq->drop_table(                # return 1 (success) or 0 (error)
          project_id => $project_id,    # required if default project is not set
          dataset_id => $dataset_id,    # required
          table_id => $table_id,        # required
        );

- show\_tables

    List tables.

        $bq->show_tables(               # return array of table_id
          project_id => $project_id,    # required if default project is not set
          dataset_id => $dataset_id,    # required if default project is not set
          maxResults => $maxResults,    # optioanl
          pageToken => $pageToken,      # optional
        );

    Use get\_nextPageToken() if you want to use pageToken.

        $bq->show_tables(maxResults => 1);
        my $nextPageToken = $bq->get_nextPageToken;
        $bq->show_tables(maxResults => 1, nextPageToken => $nextPageToken);

- desc\_table

    Describe a table.
    This method returns a Tables resource.
    See datails of a Tables resource at https://cloud.google.com/bigquery/docs/reference/v2/tables#resource.

        $bq->desc_table(                # return hashref of tables resource
          project_id => $project_id,    # required if default project is not set
          dataset_id => $dataset_id,    # required if default project is not set
          table_id => $table_id,        # required
        );

- load

    Load data from one of several formats into a table.

        $bq->load(                                  # return 1 (success) or 0 (error)
          project_id => $project_id,                # required if default project is not set
          dataset_id => $dataset_id,                # required if default project is not set
          table_id => $table_id,                    # required
          data => $data,                            # required (specify a local file or Google Cloud Storage URIs)
          allowJaggedRows => $boolean,              # optional
          allowQuotedNewlines => $boolean,          # optional
          createDisposition => $createDisposition,  # optional
          encoding => $encoding,                    # optional
          fieldDelimiter => $fieldDelimiter,        # optional
          ignoreUnknownValues => $boolean,          # optional
          maxBadRecords => $maxBadRecords,          # optional
          quote => $quote,                          # optional
          schema => $schema,                        # optional
          skipLeadingRows => $skipLeadingRows,      # optional
          sourceFormat => $sourceFormat,            # optional
          writeDisposition => $writeDisposition,    # optional
        );

- insert

    Streams data into BigQuery one record at a time without needing to run a load job.
    See details at https://cloud.google.com/bigquery/streaming-data-into-bigquery.

        $bq->insert(                    # return 1 (success) or 0 (error)
          project_id => $project_id,    # required if default project is not set
          dataset_id => $dataset_id,    # required if default project is not set
          table_id => $table_id,        # required
          values => \@values,           # required
        );

- selectrow\_array

    Select a row.

        $bq->selectrow_array(           # return array of a row
          project_id => $project_id,    # required if default project is not set
          query => $query,              # required
          dataset_id => $dataset_id,    # optional
          maxResults => $maxResults,    # optional
          timeoutMs => $timeoutMs,      # optional
          dryRun => $boolean,           # optional
          useQueryCache => $boolean,    # optional
        );

- selectall\_arrayref

    Select rows.

        $bq->selectrow_array(           # return arrayref of rows
          project_id => $project_id,    # required if default project is not set
          query => $query,              # required
          dataset_id => $dataset_id,    # optional
          maxResults => $maxResults,    # optional
          timeoutMs => $timeoutMs,      # optional
          dryRun => $boolean,           # optional
          useQueryCache => $boolean,    # optional
        );

- is\_exists\_dataset

    Check a dataset exists or not.

        $bq->is_exists_dataset(         # return 1 (exists) or 0 (no exists)
          project_id => $project_id,    # required if default project is not set
          dataset_id => $dataset_id,    # required if default project is not set
        )

- is\_exists\_table

    Check a table exists or not.

        $bq->is_exists_table(           # return 1 (exists) or 0 (no exists)
          project_id => $project_id,    # required if default project is not set
          dataset_id => $dataset_id,    # required if default project is not set
          table_id => $table_id,        # required
        )

- extract

    Export a BigQuery table to Google Cloud Storage.

        $bq->extract(                               # return 1 (success) or 0 (error)
          project_id => $project_id,                # required if default project is not set
          dataset_id => $dataset_id,                # required if default project is not set
          table_id => $table_id,                    # required
          data => $data,                            # required (specify Google Cloud Storage URIs)
          compression => $compression,              # optional
          destinationFormat => $destinationFormat,  # optional
          fieldDelimiter => $fieldDelimiter,        # optional
          printHeader => $boolean,                  # optional
        );

- request

    You can also directly request to Google BigQuery API using request() method.
    See details of Google BigQuery API at https://cloud.google.com/bigquery/docs/reference/v2/.

        $bq->request(
          resource => $resource,            # BigQuery API resource
          method => $method,                # BigQuery API method
          project_id => $project_id,        # project_id
          dataset_id => $dataset_id,        # dataset_id
          table_id => $table_id,            # table_id
          job_id => $job_id,                # job_id
          content => \%content,             # content of POST
          query_string => \%query_string,   # query string
          data => $data,                    # source localfile path for upload
        );

    e.g. Updates description in an existing table.

        $bq->request(
          resource => 'tables',
          method => 'update',
          project_id => $project_id,
          dataset_id => $dataset_id,
          table_id => $table_id,
          content => {
            talbeReferece => {
              projectId => $project_id,
              datasetId => $dataset_id,
              tableId => $table_id,
            },
            description => 'Update!',
          },
        );

# LICENSE

Copyright (C) Shoji Kai.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoji Kai <sho2kai@gmail.com>
