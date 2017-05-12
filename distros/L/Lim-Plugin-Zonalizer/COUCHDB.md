# CouchDB

## Creating

To create the CouchDB database you can use the included database management
tool.

```
zonalizer-couchdb-database --create URI
```

* `URI`: The URI to the CouchDB database.

## Updating

To update the CouchDB database between releases and modify existing objects to
work with the installed release use the included database management tool.

```
zonalizer-couchdb-database --update URI
```

* `URI`: The URI to the CouchDB database.

## Maintaining

Some maintenance of the database will be needed, this is easily management by
adding CRON job or running the following commands on a regular basis.

The following Curl commands will compact both the database and the views.

```
0 2 * * * curl -H "Content-Type: application/json" -X POST http://localhost:5984/zonalizer/_compact
0 3 * * * curl -H "Content-Type: application/json" -X POST http://localhost:5984/zonalizer/_compact/analysis
0 4 * * * curl -H "Content-Type: application/json" -X POST http://localhost:5984/zonalizer/_compact/new_analysis
```
