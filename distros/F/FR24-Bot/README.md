# FR24::Bot

[![MetaCpan](https://img.shields.io/cpan/v/FR24-Bot)](https://metacpan.org/dist/FR24-Bot)

This module comes with some utilities to run a **Telegram Bot** 
that interacts with flight data from the **Flightradar24 antenna**.

It can be installed in the same device (usually a Raspberry Pi) 
where the Flightradar24 antenna is running, or in another server
which is able to connect to the Flightradar24 antenna webpage. 
For this reason, it mostly parses data from the webserver, but 
it has been mostly tested in the same device.

## Installing the Module

Use CPAN or cpanm to install the module:

```bash
cpanm FR24::Bot
```

## Setting Up the Module

You will need a configuration file to run the bot. The default location is:

```text
~/.config/fr24-bot.ini
```

The configuration file is an INI file with the following sections:

```ini
[telegram]
apikey=7908487915:AEEQFftvQtEbavBGcB81iF1cF2koliWFxJE

[server]
port=8080
ip=localhost

[users]
everyone=1
```

To create it you can run the following command:

```bash
config-fr24-bot [-a API_KEY] [-i IP] [-p PORT]
```

If you don't specify the -a option or the -i options,
the script will ask you to provide them interactively.
Running the Bot

The main program is fr24bot. You can run it with the following options:

```bash
fr24-bot [-a API_KEY] [-i IP] [-p PORT] [-c CONFIG_FILE] [-v] [-d]
```