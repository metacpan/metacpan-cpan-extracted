Perl модуль Finance::Quote::Moex
================================

Получает онлайн котировки российских инструментов с биржи ММВБ используя perl [Finance::Quote](https://github.com/finance-quote/finance-quote)

Сделано для [GnuCash](http://www.gnucash.org/)

Котировки получаются с сайта http://moex.com

Установка
---------

Все виды установок не изменяют модуль загрузки Finance::Quote. Поэтому по умолчанию в GnuCash модуль будет не доступен. 

Для включения модуля есть три варианта:

1. Установите переменную среды перед запуском GnuCash. 

```bash
FQ_LOAD_QUOTELET="-defaults Moex" gnucash
```
2. у GnuCash есть файл настройки среды - `/etc/gnucash/enviroment` (для linux, в остальных думаю есть подобное). Достаточно в конец добавить  
```
FQ_LOAD_QUOTELET=-defaults Moex
```
3. Поправить модуль загрузки Finance::Quote, как это описано в ручной установке.

### Установка из cpan

Я добавил модуль на cpan. Можно установить из него.
В любой полной версии Perl: 
```
cpan Finance::Quote::Moex
```
Если установлен cpanminus: 
```
cpanm Finance::Quote::Moex
```

### Установка на Debian/Ubuntu


Установите пакет .deb из [releases](https://github.com/partizand/finquote/releases)

### Ручная сборка


```
make
make install
```

`make install` плохая команда. Попробуйте вместо неё `checkinstall`

На Windows в Strawberry perl использовать gmake (в старых версиях - dmake).

###  Ручная установка (не рекомендуется)

* Скопировать все файлы *.pm в каталог Finance/Quote (Для Win обычно c:\strawberry\perl\site\lib\Finance\Quote\, для linux /usr/share/perl5/Finance/quote, для Mac /Library/Perl/5.18/Finance/Quote/)

* Добавить в quote.pm (лежит на каталог выше), ссылку на новые модули

```perl
  # If we get an empty new(), or one starting with -defaults,
  # then load up the default methods.
  if (!@reqmodules or $reqmodules[0] eq "-defaults") {
    shift(@reqmodules) if (@reqmodules);
    # Default modules
    @modules = qw/AEX AIAHK ASEGR ASX BMONesbittBurns BSERO Bourso
            Cdnfundlibrary Citywire CSE Currencies Deka DWS FTPortfolios Fidelity FidelityFixed
            FinanceCanada Fool FTfunds HU GoldMoney HEX IndiaMutual LeRevenu
            ManInvestments Morningstar MorningstarJP MStaruk NZX Platinum Moex
            SEB SIXfunds SIXshares StockHouseCanada TSP TSX Tdefunds
            Tdwaterhouse Tiaacref TNetuk Troweprice Trustnet Union USFedBonds
            VWD ZA Cominvest Finanzpartner YahooJSON Yahoo::Asia
            Yahoo::Australia Yahoo::Brasil Yahoo::Europe Yahoo::NZ
            Yahoo::USA YahooYQL ZA_UnitTrusts/; }

  $this->_load_modules(@modules,@reqmodules);
```

![Добавление модуля](../master/pic/quote-add.gif)

Micex включил в Moex, поэтому модуль убрал.

Можно не редактировать quote.pm, а установить переменную среды перед запуском GnuCash

```
FQ_LOAD_QUOTELET="-defaults Moex"
```

В GnuCash заводить ценные бумаги примерно так:

![Пример в GnuCash](../master/pic/gnucash-sample.gif)


Использование
-------------

###  Облигации

Получает средневзвешенную цену предыдущего дня для облигаций на ММВБ

Функции:

* moex_bond_tplus, Т+: Основной режим - безадрес. Цена не будет включать НКД
* moex_bond_tplus_nkd, Т+: Основной режим - безадрес. Цена будет включать НКД

* moex_bond_tplus_usd, Т+: Основной режим (USD) - безадрес. Цена не будет включать НКД
* moex_bond_tplus_usd_nkd, Т+: Основной режим (USD) - безадрес. Цена будет включать НКД

* moex_bond_tplus_eur, Т+: Облигации (EUR) - безадрес. Цена не будет включать НКД
* moex_bond_tplus_eur_nkd, Т+: Облигации (EUR) - безадрес. Цена будет включать НКД

* moex_bond_tplus_pir, Т+ Облигации ПИР - безадрес. Цена не будет включать НКД
* moex_bond_tplus_pir_nkd, Т+ Облигации ПИР - безадрес. Цена будет включать НКД

* moex_bond_tplus_pir_usd, Т+: Облигации ПИР (USD) - безадрес. Цена не будет включать НКД
* moex_bond_tplus_pir_usd_nkd, Т+: Облигации ПИР (USD) - безадрес. Цена будет включать НКД

Тикер указывать как на Мосбирже. Например SU26218RMFS6 - ОФЗ 26218, RU000A0JSGV0 - РЖД-32. Найти обозначение тикеров можно по поиску инструмента на [сайте биржи](http://www.moex.com)

![Пример в GnuCash](../master/pic/moexbonds-example.png)

###  Акции

Получает цену закрытия предыдущего торгового дня российских акций на ММВБ.

Функция moex_stock

Котировки берутся с сайта Мосбиржи.

![Пример в GnuCash](../master/pic/gnucash-sample.gif)

Используйте тип "Неизвестный" и функцию moex_stock. 

Тестирование
------------

```
ONLINE_TEST="y" make test 
```
