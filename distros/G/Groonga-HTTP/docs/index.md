---
title: none
---

<div class="jumbotron">
  <h1>Groonga-HTTP</h1>
  <p>{{ site.description.en }}</p>
  <p>The latest version
     (<a href="news/#version-{{ site.version | replace:".", "-" }}">{{ site.version }}</a>)
     has been released at {{ site.release_date }}.
  </p>
  <p>
    <a href="tutorial/"
       class="btn btn-primary btn-lg"
       role="button">Try tutorial</a>
    <a href="install/"
       class="btn btn-primary btn-lg"
       role="button">Install</a>
  </p>
</div>

## About Groonga-HTTP {#about}

Groonga-HTTP is a Perl module for sending HTTP requests to Groonga.

Groonga-HTTP provides user-friendly Web API instead of low-level Groonga Web API. The user-friendly Web API is implemented top of the low-level Groonga Web API.

## Documentations {#documentations}

  * [News][news]: It lists release information.

  * [Install][install]: It describes how to install Groonga-HTTP.

  * [Tutorial][tutorial]: It describes how to use Groonga-HTTP step by step.

  * [Reference][reference]: It describes details for each features such as classes and methods.

## License {#license}

Groonga-HTTP is released under [the GNU Lesser General Public License version 3 or later][lgpl3.0-license].

[news]:news/

[install]:install/

[tutorial]:tutorial/

[reference]:reference/

[lgpl3.0-license]:https://opensource.org/licenses/LGPL-3.0
