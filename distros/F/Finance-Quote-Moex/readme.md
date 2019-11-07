Perl модуль Finance::Quote::Moex
================================

Получает онлайн котировки российских инструментов с биржи ММВБ используя perl [Finance::Quote](https://github.com/finance-quote/finance-quote)

Сделано для [GnuCash](http://www.gnucash.org/)

Котировки получаются с сайтов http://rbc.ru и http://moex.com

Установка
---------

Все виды установок не изменяют модуль загрузки Finance::Quote. Поэтому по умолчанию в GnuCash модуль будет не доступен. Для включения установите переменную среды перед запуском GnuCash. 

```bash
FQ_LOAD_QUOTELET="-defaults Moex" gnucash
```

Или поправьте модуль загрузки, как это описано в ручной установке.

### Установка на Debian/Ubuntu


Установите пакет .deb из [releases](https://github.com/partizand/finquote/releases)

### Ручная сборка


```
make
make install
```

`make install` плохая команда. Попробуйте вместо неё `checkinstall`

На Windows вроде make нет.

Возможно удастся разместить на cpan

###  Ручная установка (не рекомендуется)

Для Windows сойдёт.

* Скопировать все файлы *.pm в каталог Finance/Quote (Для Win обычно c:\strawberry\perl\site\lib\Finance\Quote\, для linux /usr/share/perl5/Finance/quote)

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
FQ_LOAD_QUOTELET="-defaults Micex Moex"
```

В GnuCash заводить ценные бумаги примерно так:

![Пример в GnuCash](../master/pic/gnucash-sample.gif)


Использование
-------------

###  Облигации

Получает средневзвешенную цену предыдущего дня для облигаций на ММВБ

Функции:
* moex_bond_ofz, Облигации в режиме T1, в основном ОФЗ. Цена не будет включать НКД
* moex_bond, Облигации в режиме T0, все кроме ОФЗ. Цена не будет включать НКД
* moex_bond_ofz_nkd, Облигации в режиме T1, в основном ОФЗ. Цена будет включать НКД
* moex_bond_nkd, Облигации в режиме T0, все кроме ОФЗ. Цена будет включать НКД

Тикер указывать как на Мосбирже. Например SU26218RMFS6 - ОФЗ 26218, RU000A0JSGV0 - РЖД-32. Найти обозначение тикеров можно по поиску инструмента на [сайте биржи](http://www.moex.com)

![Пример в GnuCash](../master/pic/moexbonds-example.png)

###  Акции

Получает цену закрытия предыдущего торгового дня российских акций на ММВБ.

Функция micex

Котировки берутся с сайта http://export.rbc.ru/

![Пример в GnuCash](../master/pic/gnucash-sample.gif)

Используйте модуль Moex (тип) и функцию micex из него. Объединил модули, картинки переснимать лень.

Тестирование
------------

```
ONLINE_TEST="y" make test 
```
