#Proof of concept application to show how nice modern Javascript and modern Perl play together

##Technologies

### Perl

* Mojolicious
* DBIx::Class

### Javascript

* Backbone.js
* require.js
* underscore.js
* bootstrap from twitter


##Getting Started

###1. Clone the repository
<pre>git clone git://github.com/tudorconstantin/expense-tracker.git</pre>

####1.1 cd into the cloned directory
<pre>cd expense-tracker</pre>

###2. Install Dist::Zilla from CPAN
<pre> cpan Dist::Zilla </pre>

###3. Install Dist::Zilla's required plugins
<pre>dzil authordeps | xargs cpan </pre>

###4. Install Perl dependencies for this application
<pre>dzil listdeps | xargs cpan</pre>

###5. Start the app in dev mode
<pre>morbo script/expense-tracker</pre>

#Project Wiki

* [Backend Architecture](https://github.com/tudorconstantin/expense-tracker/wiki/Backend-Architecture)

